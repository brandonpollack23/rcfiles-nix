# Pulls the latest rcfiles-nix checkout and rebuilds NixOS at 3 AM.
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.rcfiles_nix.autoUpgrade;
  stateDir = lib.escapeShellArg cfg.stateDir;

  notifyScript = pkgs.writeShellScript "rcfiles-notify-upgrade-failure" ''
    f="${cfg.stateDir}/failure"
    [ -f "$f" ] || exit 0
    ${pkgs.noti}/bin/noti -t "rcfiles Auto-Upgrade Failed" -m "$(cat "$f")"
  '';
in {
  config = lib.mkIf cfg.enable {
    systemd.timers.nixos-auto-upgrade = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
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
      path = with pkgs; [git nix coreutils gnutar gzip xz];
      script = ''
        set -uo pipefail

        STATE_DIR=${stateDir}
        FAILURE_FILE="$STATE_DIR/failure"
        FLAKE_PATH=$(cat /etc/rcfiles-nix/flake-path)

        mkdir -p "$STATE_DIR"
        chown brpol:users "$STATE_DIR"

        record_failure() {
          printf '%s: %s\n' "$(date -Iseconds)" "$1" > "$FAILURE_FILE"
          chown brpol:users "$FAILURE_FILE"
        }

        # Pull via HTTPS — no SSH key required; leaves the repo's configured
        # remote unchanged so the user can still push via SSH.
        git -c safe.directory="$FLAKE_PATH" -C "$FLAKE_PATH" \
          pull --ff-only https://github.com/brandonpollack23/rcfiles-nix.git
        pull_rc=$?

        if [ $pull_rc -ne 0 ]; then
          record_failure "git pull --ff-only failed; manually resolve in $FLAKE_PATH and try again"
          exit 1
        fi

        ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake "$FLAKE_PATH"
        rebuild_rc=$?

        if [ $rebuild_rc -ne 0 ]; then
          record_failure "nixos-rebuild switch failed; manually resolve in $FLAKE_PATH and try again"
          exit 1
        fi

        rm -f "$FAILURE_FILE"
      '';
    };

    # Pre-create the state dir with correct ownership so brpol can delete the failure file.
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 brpol users -"
    ];

    # Path unit: fires immediately when the failure file appears (while user is logged in).
    systemd.user.paths.rcfiles-upgrade-failure = {
      wantedBy = ["default.target"];
      pathConfig.PathChanged = "${cfg.stateDir}/failure";
    };

    # Service: sends a noti popup. Also starts at graphical-session.target to
    # catch failures that happened while the user was away.
    systemd.user.services.rcfiles-upgrade-failure = {
      description = "Notify about rcfiles auto-upgrade failure";
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${notifyScript}";
      };
    };

    programs.git = {
      enable = true;
      config = {
        safe.directory = "${config.users.users.brpol.home}/rcfiles-nix";
      };
    };

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
