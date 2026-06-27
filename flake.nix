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
    # nixosConfiguration. Stubs without meta.nix are silently skipped.
    # To add a host: create hosts/<name>/{default,hardware-configuration,meta}.nix.
    hostDirs = lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./hosts);
    hostNames = lib.attrNames (lib.filterAttrs (name: _: (builtins.readDir ./hosts/${name}) ? "meta.nix") hostDirs);

    # Registry mapping hostname -> user SSH public key.  Hosts without a user.pub
    # file resolve to null; the allow-list resolver in mkHost filters those out.
    hostUserKeys = lib.genAttrs hostNames (name: let
      f = ./hosts/${name}/user.pub;
    in
      if builtins.pathExists f
      then lib.removeSuffix "\n" (builtins.readFile f)
      else null);
  in {
    nixosConfigurations =
      lib.genAttrs hostNames
      (hostname: myLib.mkHost (import ./hosts/${hostname}/meta.nix // {inherit hostname hostUserKeys;}));

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
