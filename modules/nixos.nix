# NixOS-only configuration imported for every NixOS host via mkHost.
# Mirror of modules/darwin.nix — put NixOS-specific shared policy here.
{config, ...}: {
  # programs.nh owns store cleanup on NixOS; replaces the old nix.gc systemd
  # timer (see old/nix-gc-service.nix for the previous setup).
  programs.nh = {
    enable = true;
    flake = "${config.users.users.brpol.home}/rcfiles-nix";
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 3";
    };
  };
}
