# nix-darwin has no programs.nh module; set NH_FLAKE directly so rebuild/darwin.nix
# and the auto-upgrade launchd agent can invoke `nh darwin switch`.
{config, ...}: {
  environment.variables.NH_FLAKE = "${config.users.users.brpol.home}/rcfiles-nix";
}
