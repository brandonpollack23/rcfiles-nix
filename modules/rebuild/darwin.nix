{
  pkgs,
  config,
  ...
}: {
  config.rcfiles_nix.rebuild.script = pkgs.writeShellScript "nrs" ''
    darwin-rebuild switch --flake "$(cat /etc/rcfiles-nix/flake-path)" "$@"
    rc=$?
    if [ $rc -eq 0 ]; then
      rm -f ${config.rcfiles_nix.autoUpgrade.stateDir}/failure
    fi
    exit $rc
  '';
}
