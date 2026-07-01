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
  rebaseTarget = lib.escapeShellArg "${cfg.remoteBranch}@origin";

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
        jujutsu
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
        REBASE_TARGET=${rebaseTarget}

        ${pkgs.coreutils}/bin/mkdir -p "$STATE_DIR"

        record_failure() {
          ${pkgs.coreutils}/bin/printf '%s: %s\n' "$(${pkgs.coreutils}/bin/date -Iseconds)" "$1" > "$FAILURE_FILE"
        }

        # All jj operations run as brpol, the checkout's owner; only the rebuild
        # needs root. /usr/bin/sudo is the setuid system sudo on macOS.
        jj_as_brpol() {
          /usr/bin/sudo -u brpol -- ${pkgs.jujutsu}/bin/jj -R "$BRANDON_SYSTEM_FLAKE_DIR" "$@"
        }

        if [ ! -d "$BRANDON_SYSTEM_FLAKE_DIR/.jj" ]; then
          if [ -d "$BRANDON_SYSTEM_FLAKE_DIR/.git" ]; then
            # Upgrade a plain git checkout to a colocated jj repo in-place.
            /usr/bin/sudo -u brpol -- ${pkgs.jujutsu}/bin/jj git init --colocate "$BRANDON_SYSTEM_FLAKE_DIR"
          else
            record_failure "no jj or git checkout at $BRANDON_SYSTEM_FLAKE_DIR; run brpol-setup / home activation first"
            exit 1
          fi
        fi

        # Fetch from origin. Origin must be configured as the HTTPS remote so no
        # SSH key is required. (brpol-setup switches origin to SSH for interactive
        # use; set it back to HTTPS here if the service fails with auth errors.)
        if ! jj_as_brpol git fetch; then
          record_failure "jj git fetch failed in $BRANDON_SYSTEM_FLAKE_DIR; check network and origin remote URL"
          exit 1
        fi

        # Rebase local commits on top of the fetched remote bookmark.
        if ! jj_as_brpol rebase -d "$REBASE_TARGET"; then
          record_failure "jj rebase onto $REBASE_TARGET failed in $BRANDON_SYSTEM_FLAKE_DIR; manually resolve and retry"
          exit 1
        fi

        # Fail if the rebase left any conflict markers rather than silently
        # rebuilding a broken config.
        if [ -n "$(jj_as_brpol log -r 'conflicts()' --no-graph -T 'commit_id')" ]; then
          record_failure "jj rebase produced conflicts in $BRANDON_SYSTEM_FLAKE_DIR; run 'jj undo' then resolve manually and retry"
          jj_as_brpol undo
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
