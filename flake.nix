{
  description = "Brandon's nixos flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim.url = "github:nix-community/neovim-nightly-overlay";
    nixos-cli.url = "github:nix-community/nixos-cli";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    determinate,
    home-manager,
    ...
  }: {
    nixosConfigurations.vmnixos = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./configuration.nix
        determinate.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.brpol = import ./home.nix;
        }
      ];
    };
  };
}
