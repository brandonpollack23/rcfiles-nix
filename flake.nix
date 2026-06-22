{
  description = "Brandon's nixos flake";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    determinate,
    ...
  }: {
    nixosConfigurations.vmnixos = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        determinate.nixosModules.default
      ];
    };
  };
}
