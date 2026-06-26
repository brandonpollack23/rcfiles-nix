# To add a new host/machine, add an entry to hostConfigs in flake.nix — the key becomes hostname.
{
  nixpkgs,
  home-manager,
  determinate,
  neovim,
  nixos-cli,
  sops-nix,
  darwin ? null,
  self,
  ...
}: rec {
  resolveHostKeys = import ./resolve-host-keys.nix {lib = nixpkgs.lib;};
  mkHost = import ./mk-host.nix {
    lib = nixpkgs.lib;
    inherit home-manager determinate neovim nixos-cli sops-nix darwin resolveHostKeys self;
  };
}
