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

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Fast-moving CLI packages sourced directly from their upstream flakes.
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim.url = "github:nix-community/neovim-nightly-overlay";

    tmux-menus = {
      url = "github:jaclu/tmux-menus";
      flake = false;
    };
    tmux-easy-motion = {
      url = "github:IngoMeyer441/tmux-easy-motion";
      flake = false;
    };
  };

  outputs = inputs: let
    lib = inputs.nixpkgs.lib;
    myLib = import ./lib inputs;

    # Auto-discover hosts: every subdirectory of hosts/ that contains a meta.nix becomes a
    # configuration. Stubs without meta.nix are silently skipped.
    # To add a host: create hosts/<name>/{default,hardware-configuration,meta}.nix.
    hostDirs = lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./hosts);
    hostNames = lib.attrNames (lib.filterAttrs (name: _: (builtins.readDir ./hosts/${name}) ? "meta.nix") hostDirs);

    # Read each host's meta.nix to determine platform, then partition.
    hostMeta = lib.genAttrs hostNames (name: import ./hosts/${name}/meta.nix);
    nixosHostNames = builtins.filter (name: !(hostMeta.${name}.isDarwin or false)) hostNames;
    darwinHostNames = builtins.filter (name: (hostMeta.${name}.isDarwin or false)) hostNames;

    # Registry mapping hostname -> user SSH public key.  Hosts without a user.pub
    # file resolve to null; the allow-list resolver in mkHost filters those out.
    hostUserKeys = lib.genAttrs hostNames (name: let
      f = ./hosts/${name}/user.pub;
    in
      if builtins.pathExists f
      then lib.removeSuffix "\n" (builtins.readFile f)
      else null);

    mkHostConfig = hostname: myLib.mkHost (import ./hosts/${hostname}/meta.nix // {inherit hostname hostUserKeys;});
  in {
    nixosConfigurations = lib.genAttrs nixosHostNames mkHostConfig;
    darwinConfigurations = lib.genAttrs darwinHostNames mkHostConfig;

    checks.x86_64-linux = {
      ssh-keyring = import ./tests/ssh-keyring.nix {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      };

      rcfiles-seeding = import ./tests/rcfiles-seeding.nix {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      };
    };
  };
}
