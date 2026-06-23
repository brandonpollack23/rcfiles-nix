# To add a new host/machine:
#   nixosConfigurations.my-host = myLib.mkHost { hostname = "my-host"; users = [ "brpol" ]; };
{
  nixpkgs,
  home-manager,
  determinate,
  neovim,
  nixos-cli,
  darwin ? null,
  ...
}: let
  lib = nixpkgs.lib;
in rec {
  mkHost = {
    hostname, # must match a directory under hosts/
    stateVersion, # e.g. "26.05" — single source of truth for system + home stateVersion
    isDarwin ? false, # true for Macintosh
    enableDesktop ? true, # include modules/desktop.nix (GUI stack, sound, printing)
    users ? ["brpol"], # list of usernames; each must have users/<name>/nixos.nix + home/
    rootAuthorizedKeys ? [], # SSH public keys granted access to root on this host
    userAuthorizedKeys ? {}, # attrset of username -> SSH public keys, e.g. { brpol = [ "ssh-ed25519 ..." ]; }
    grubTheme ? ../grub-themes/fallout, # path to a GRUB theme directory, e.g. ./grub-themes/fallout
  }: let
    nixSystem =
      if isDarwin
      then darwin.lib.darwinSystem
      else lib.nixosSystem;
    home-manager-module =
      if isDarwin
      then home-manager.darwinModules.home-manager
      else home-manager.nixosModules.home-manager;
  in
    nixSystem {
      specialArgs = {
        inherit stateVersion rootAuthorizedKeys grubTheme;
        neovimPkg = neovim.packages;
        nixosCliPkg = nixos-cli.packages;
      };
      modules =
        [
          # Opinionated nix daemon settings from Determinate Systems.
          determinate.nixosModules.default

          # Host-specific config: bootloader, hostname, timezone, stateVersion, hardware.
          ../hosts/${hostname}

          # Shared baseline: nix settings, locale, base packages, ssh, zsh, root key.
          ../modules/common.nix

          # Wires home-manager into NixOS (or Darwin) so user home configs are
          # built as part of nixos-rebuild.
          home-manager-module
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # stateVersion flows into every user's home config from the single mkHost param.
            home-manager.extraSpecialArgs = {inherit stateVersion;};
            # Each user gets their own users/<name>/home/ directory as their HM config.
            home-manager.users =
              lib.genAttrs users (user: import ../users/${user}/home);
          }

          # Per-user SSH authorized keys, injected here so user modules stay key-agnostic.
          {
            users.users =
              lib.mapAttrs (_user: keys: {
                openssh.authorizedKeys.keys = keys;
              })
              userAuthorizedKeys;
          }
        ]
        ++ lib.optional (!isDarwin) ../modules/boot.nix
        ++ lib.optional enableDesktop ../modules/desktop.nix
        # Pull in each user's system-level modules (shared default + OS-specific).
        ++ builtins.concatMap (userModules {inherit isDarwin;}) users;
    };

  # Returns the system-level modules for a given username: the shared default.nix
  # plus the OS-specific nixos.nix or darwin.nix.
  userModules = {isDarwin}: user: [
    ../users/${user}/default.nix
    ../users/${user}/${
      if isDarwin
      then "darwin.nix"
      else "nixos.nix"
    }
  ];
}
