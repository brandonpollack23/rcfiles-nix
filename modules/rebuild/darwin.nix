{
  pkgs,
  lib,
  config,
  ...
}: {
  config.rcfiles_nix.rebuild.script = pkgs.writeShellApplication {
    name = "nrs";
    runtimeInputs = [pkgs.nh pkgs.coreutils];
    text = ''
      # NH_FLAKE is exported system-wide by programs.nh.
      update_homebrew=0
      if [ "''${1:-}" = "--homebrew-update" ]; then
        update_homebrew=1
        shift
      fi

      rc=0
      nh darwin switch "$NH_FLAKE" "$@" || rc=$?

      if [ "$rc" -eq 0 ] && [ "$update_homebrew" -eq 1 ]; then
        brew=${lib.escapeShellArg "${config.homebrew.prefix}/bin/brew"}
        if [ ! -x "$brew" ]; then
          echo "nrs: Homebrew executable not found at $brew" >&2
          rc=1
        else
          echo "> Updating Homebrew" >&2
          "$brew" update || rc=$?
          if [ "$rc" -eq 0 ]; then
            HOMEBREW_NO_AUTO_UPDATE=1 "$brew" upgrade --formula || rc=$?
          fi
          if [ "$rc" -eq 0 ]; then
            HOMEBREW_NO_AUTO_UPDATE=1 "$brew" upgrade --cask || rc=$?
          fi
        fi
      fi

      if [ "$rc" -eq 0 ]; then
        rm -f ${lib.escapeShellArg "${config.rcfiles_nix.autoUpgrade.stateDir}/failure"}
      fi
      exit "$rc"
    '';
  };
}
