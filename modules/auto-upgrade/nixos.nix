# Pulls the latest rcfiles-nix checkout and rebuilds NixOS at 3 AM.
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.rcfiles_nix.autoUpgrade;
  stateDir = lib.escapeShellArg cfg.stateDir;
  flakePath = lib.escapeShellArg cfg.flakePath;
  repoUrl = lib.escapeShellArg cfg.repoUrl;

  notifyScript = pkgs.writeShellScript "rcfiles-notify-upgrade-failure" ''
    f=${stateDir}/failure
    [ -f "$f" ] || exit 0
    ${pkgs.noti}/bin/noti -t "rcfiles Auto-Upgrade Failed" -m "$(${pkgs.coreutils}/bin/cat "$f")"
  '';

  # Login catch-up entry. Runs notifyScript via XDG autostart instead of a
  # graphical-session.target systemd user service, which Cinnamon+LightDM does
  # not reliably activate (same workaround as the home age-key notify).
  upgradeFailureNotify = pkgs.makeDesktopItem {
    name = "rcfiles-upgrade-failure";
    desktopName = "rcfiles Auto-Upgrade Failure Notification";
    exec = "${notifyScript}";
    # Cinnamon/GNOME read this to decide whether to run the entry at login.
    extraConfig."X-GNOME-Autostart-enabled" = "true";
  };
in {
  config = lib.mkIf cfg.enable {
    systemd.timers.nixos-auto-upgrade = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
        # Spread load / avoid every host hammering GitHub at exactly 03:00.
        RandomizedDelaySec = "30min";
      };
    };

    systemd.services.nixos-auto-upgrade = {
      description = "Pull latest rcfiles-nix and switch NixOS generation";
      restartIfChanged = false;
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig.Type = "oneshot";
      environment = {
        HOME = "/root";
      };
      # nh wraps nixos-rebuild, which shells out to git and nix; keep them all
      # on PATH for it.
      path = with pkgs; [nh nixos-rebuild git nix coreutils gnutar gzip xz util-linux];
      script = ''
        set -uo pipefail

        STATE_DIR=${stateDir}
        FAILURE_FILE="$STATE_DIR/failure"
        BRANDON_SYSTEM_FLAKE_DIR=${flakePath}
        REPO_URL=${repoUrl}

        ${pkgs.coreutils}/bin/mkdir -p "$STATE_DIR"

        record_failure() {
          ${pkgs.coreutils}/bin/printf '%s: %s\n' "$(${pkgs.coreutils}/bin/date -Iseconds)" "$1" > "$FAILURE_FILE"
        }

        # All git operations run as brpol, the checkout's owner; only the rebuild
        # needs root. This avoids root-owned objects and the safe.directory dance.
        git_as_brpol() {
          ${pkgs.util-linux}/bin/runuser -u brpol -- ${pkgs.git}/bin/git -C "$BRANDON_SYSTEM_FLAKE_DIR" "$@"
        }

        if [ ! -d "$BRANDON_SYSTEM_FLAKE_DIR/.git" ]; then
          record_failure "no git checkout at $BRANDON_SYSTEM_FLAKE_DIR; run brpol-setup / home activation first"
          exit 1
        fi

        # Refuse to touch a dirty or untracked checkout — an auto-pull could
        # clobber local work, and rebase refuses to run on a dirty tree anyway.
        if [ -n "$(git_as_brpol status --porcelain)" ]; then
          record_failure "checkout at $BRANDON_SYSTEM_FLAKE_DIR has uncommitted or untracked changes; resolve manually and retry"
          exit 1
        fi

        # Pull via HTTPS — no SSH key required; leaves the repo's configured
        # remote unchanged so the user can still push via SSH. --rebase replays
        # any local commits on top of upstream (never a merge commit); a real
        # conflict aborts the rebase so the checkout is left clean rather than
        # mid-rebase, and the failure is recorded for manual resolution.
        if ! git_as_brpol pull --rebase "$REPO_URL"; then
          git_as_brpol rebase --abort 2>/dev/null || true
          record_failure "git pull --rebase failed (likely conflicts); manually resolve in $BRANDON_SYSTEM_FLAKE_DIR and try again"
          exit 1
        fi

        if ! ${pkgs.nh}/bin/nh os switch "$BRANDON_SYSTEM_FLAKE_DIR"; then
          record_failure "nh os switch failed; manually resolve in $BRANDON_SYSTEM_FLAKE_DIR and try again"
          exit 1
        fi

        ${pkgs.coreutils}/bin/rm -f "$FAILURE_FILE"
      '';
    };

    # Pre-create the state dir, owned by brpol so the nrs wrapper (run as brpol)
    # can delete the failure marker that this root service writes into it.
    systemd.tmpfiles.settings."10-rcfiles-auto-upgrade".${cfg.stateDir}.d = {
      user = "brpol";
      group = "users";
      mode = "0755";
    };

    # Path unit: fires immediately when the failure file appears (while user is logged in).
    systemd.user.paths.rcfiles-upgrade-failure = {
      wantedBy = ["default.target"];
      pathConfig.PathChanged = "${cfg.stateDir}/failure";
    };

    # Service: sends a noti popup. Triggered by the path unit above when the
    # failure file changes while the user is logged in. The catch-up for a
    # failure that occurred while logged out is handled by the XDG autostart
    # entry below, not graphical-session.target (unreliable under Cinnamon).
    systemd.user.services.rcfiles-upgrade-failure = {
      description = "Notify about rcfiles auto-upgrade failure";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${notifyScript}";
      };
    };

    # Login catch-up: XDG autostart runs in the full session environment
    # (DISPLAY/DBUS available) so noti can show the popup for a failure that
    # happened while the user was logged out. Reliable under Cinnamon+LightDM,
    # unlike a graphical-session.target systemd user service.
    environment.etc."xdg/autostart/rcfiles-upgrade-failure.desktop".source = "${upgradeFailureNotify}/share/applications/rcfiles-upgrade-failure.desktop";

    # MOTD-style text warning for SSH / TTY / headless logins.
    environment.etc."profile.d/rcfiles-upgrade-warn.sh".text = ''
      _rcfiles_failure="${cfg.stateDir}/failure"
      if [ -f "$_rcfiles_failure" ]; then
        printf '\033[1;31m\nWARNING: rcfiles auto-upgrade failed:\033[0m\n'
        cat "$_rcfiles_failure"
        printf '\n'
      fi
      unset _rcfiles_failure
    '';

    # zsh login shells use a separate init path on NixOS.
    programs.zsh.loginShellInit = ''
      _rcfiles_failure="${cfg.stateDir}/failure"
      if [ -f "$_rcfiles_failure" ]; then
        printf '\033[1;31m\nWARNING: rcfiles auto-upgrade failed:\033[0m\n'
        cat "$_rcfiles_failure"
        printf '\n'
      fi
      unset _rcfiles_failure
    '';
  };
}
