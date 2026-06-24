{
  pkgs,
  config,
  ...
}: {
  config.rcfiles_nix.rebuild.script = pkgs.writeShellScript "nrs" ''
    sudo nixos-rebuild switch --flake ~/rcfiles-nix "$@"
    rc=$?
    if [ $rc -eq 0 ]; then
      rm -f ${config.rcfiles_nix.autoUpgrade.stateDir}/failure
    fi
    exit $rc
  '';
}
