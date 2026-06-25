# Pulls the latest rcfiles-nix checkout and rebuilds nix-darwin at 3 AM.
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
    launchd.daemons.rcfiles-auto-upgrade = {
      path = with pkgs; [
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
        FLAKE_PATH=$(cat /etc/rcfiles-nix/flake-path)

        mkdir -p "$STATE_DIR"
        chown brpol:staff "$STATE_DIR"

        record_failure() {
          printf '%s: %s\n' "$(date -Iseconds)" "$1" > "$FAILURE_FILE"
          chown brpol:staff "$FAILURE_FILE"
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

        darwin-rebuild switch --flake "$FLAKE_PATH"
        rebuild_rc=$?

        if [ $rebuild_rc -ne 0 ]; then
          record_failure "darwin-rebuild switch failed; manually resolve in $FLAKE_PATH and try again"
          exit 1
        fi

        rm -f "$FAILURE_FILE"
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
