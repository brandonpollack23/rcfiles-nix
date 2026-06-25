{
  description = "Brandon's nixos flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim.url = "github:nix-community/neovim-nightly-overlay";
    nixos-cli.url = "github:nix-community/nixos-cli";
  };

  outputs = inputs: let
    lib = inputs.nixpkgs.lib;
    myLib = import ./lib inputs;

    # Auto-discover hosts: every subdirectory of hosts/ that contains a meta.nix becomes a
    # nixosConfiguration. Stubs without meta.nix are silently skipped.
    # To add a host: create hosts/<name>/{default,hardware-configuration,meta}.nix.
    hostDirs = lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./hosts);
    hostNames = lib.attrNames (lib.filterAttrs (name: _: (builtins.readDir ./hosts/${name}) ? "meta.nix") hostDirs);
  in {
    nixosConfigurations =
      lib.genAttrs hostNames
      (hostname: myLib.mkHost (import ./hosts/${hostname}/meta.nix // {inherit hostname;}));
  };
}
