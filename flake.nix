{
  description = "Brandon's nixos flake";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    neovim.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    determinate,
    ...
  }: {
    nixosConfigurations.vmnixos = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./configuration.nix
        determinate.nixosModules.default
      ];
    };
  };
}
