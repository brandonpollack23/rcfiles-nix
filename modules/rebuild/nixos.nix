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
      rc=0
      nh os switch "$NH_FLAKE" "$@" || rc=$?
      if [ "$rc" -eq 0 ]; then
        rm -f ${lib.escapeShellArg "${config.rcfiles_nix.autoUpgrade.stateDir}/failure"}
      fi
      exit "$rc"
    '';
  };
}
