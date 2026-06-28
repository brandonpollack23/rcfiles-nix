# Pulls the latest rcfiles-nix checkout and rebuilds nix-darwin at 3 AM.
#
# Dormant: kept in sync with the NixOS implementation as a compatibility
# contract. It has NOT been evaluated on a real Darwin host.
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
in {
  config = lib.mkIf cfg.enable {
    launchd.daemons.rcfiles-auto-upgrade = {
      path = with pkgs; [
        nh
        git
        nix
        coreutils
        gnutar
        gzip
        xz
        "/run/current-system/sw/bin"
      ];
      environment.HOME = "/var/root";
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
        # needs root. /usr/bin/sudo is the setuid system sudo on macOS.
        git_as_brpol() {
          /usr/bin/sudo -u brpol -- ${pkgs.git}/bin/git -C "$BRANDON_SYSTEM_FLAKE_DIR" "$@"
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

        if ! ${pkgs.nh}/bin/nh darwin switch "$BRANDON_SYSTEM_FLAKE_DIR"; then
          record_failure "nh darwin switch failed; manually resolve in $BRANDON_SYSTEM_FLAKE_DIR and try again"
          exit 1
        fi

        ${pkgs.coreutils}/bin/rm -f "$FAILURE_FILE"
      '';
      serviceConfig = {
        StartCalendarInterval = [
          {
            Hour = 3;
            Minute = 0;
          }
        ];
        StandardOutPath = "/var/log/rcfiles-auto-upgrade.log";
        StandardErrorPath = "/var/log/rcfiles-auto-upgrade.log";
      };
    };

    # Pre-create the state dir, owned by brpol so the nrs wrapper (run as brpol)
    # can delete the failure marker that this root daemon writes into it.
    system.activationScripts.postActivation.text = lib.mkAfter ''
      ${pkgs.coreutils}/bin/mkdir -p ${stateDir}
      ${pkgs.coreutils}/bin/chown brpol:staff ${stateDir}
      ${pkgs.coreutils}/bin/chmod 0755 ${stateDir}
    '';

    # User agent: watches failure file (WatchPaths fires immediately on creation)
    # and runs at login (RunAtLoad) to catch pre-existing failures.
    launchd.user.agents.rcfiles-upgrade-notify = {
      serviceConfig = {
        ProgramArguments = ["${notifyScript}"];
        WatchPaths = ["${cfg.stateDir}/failure"];
        RunAtLoad = true;
      };
    };

    # MOTD-style text warning for terminal / SSH logins.
    environment.etc."profile.d/rcfiles-upgrade-warn.sh".text = ''
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
