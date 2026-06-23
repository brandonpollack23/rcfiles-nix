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

  outputs = inputs: let
    myLib = import ./lib inputs;
    keys.ncc1701e = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ+LxALPXfkVQ3MxQu3h0pkZ3o+OtY5cSfFgf5lkTlD0 brpol@ncc-1701e";
  in {
    nixosConfigurations = {
      vmnixos = myLib.mkHost {
        hostname = "vmnixos";
        stateVersion = "26.05";
        enableDesktop = true;
        users = ["brpol"];
        rootAuthorizedKeys = [keys.ncc1701e];
        userAuthorizedKeys = {
          brpol = [keys.ncc1701e];
        };
        grubTheme = ./grub-themes/fallout;
      };

      # Adding a second host is this easy:
      # another-host = myLib.mkHost { hostname = "another-host"; users = [ "brpol" ]; };
    };
  };
}
