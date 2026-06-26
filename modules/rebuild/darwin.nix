{
  pkgs,
  config,
  ...
}: {
  config.rcfiles_nix.rebuild.script = pkgs.writeShellScript "nrs" ''
    nh darwin switch "$NH_FLAKE" "$@"
    rc=$?
    if [ $rc -eq 0 ]; then
      rm -f ${config.rcfiles_nix.autoUpgrade.stateDir}/failure
    fi
    exit $rc
  '';
}
