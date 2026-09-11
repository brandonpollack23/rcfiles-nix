# nix-darwin has no programs.nh module, so install nh and set NH_FLAKE directly.
{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.nh];
  environment.variables.NH_FLAKE = "${config.users.users.brpol.home}/rcfiles-nix";
}
