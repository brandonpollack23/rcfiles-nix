{
  lib,
  home-manager,
  determinate,
  neovim,
  sops-nix,
  tmux-menus,
  tmux-easy-motion,
  darwin ? null,
  self,
}: let
  # Lib helpers imported directly; Nix is lazy so there's no need to thread these
  # through lib/default.nix.
  resolveHostKeys = import ./resolve-host-keys.nix {inherit lib;};
  hostHomeOverrides = import ./host-home-overrides.nix {inherit lib;};
  userModules = {isDarwin}: user: [
    ../users/${user}/default.nix
    ../users/${user}/${
      if isDarwin
      then "darwin.nix"
      else "nixos.nix"
    }
  ];
in
  {
    hostname, # must match a directory under hosts/
    stateVersion, # e.g. "26.05" — single source of truth for system + home stateVersion
    isDarwin ? false, # true for Macintosh
    enableDesktop ? true, # include modules/desktop.nix (GUI stack, sound, printing)
    enableSteam ? false, # whether or not to enable steam
    users ? ["brpol"], # list of usernames; each must have users/<name>/nixos.nix + home/
    rootAuthorizedKeys ? [], # SSH public keys granted access to root on this host (escape hatch)
    userAuthorizedKeys ? {}, # attrset of username -> SSH public keys (escape hatch)
    allowedSSHHosts ? [], # hostnames whose registered user.pub may SSH in as root + every user
    hostUserKeys ? {}, # registry passed in from flake.nix: hostname -> pubkey or null
  }: let
    allowedKeys = resolveHostKeys {inherit hostname allowedSSHHosts hostUserKeys;};
    finalRootKeys = rootAuthorizedKeys ++ allowedKeys;
    # Give every user on this host the same set of allow-list keys. (for now, this can be modified to use the param)
    allowedKeysByUser = lib.genAttrs users (_: allowedKeys);
    # Merge the escape-hatch per-user keys with the allow-list keys, concatenating
    # the two lists when the same username appears in both attrsets.
    mergedUserKeys = lib.zipAttrsWith (_: lib.concatLists) [
      userAuthorizedKeys
      allowedKeysByUser
    ];

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
        inherit hostname stateVersion isDarwin enableSteam;
        rootAuthorizedKeys = finalRootKeys;
        neovimPkg = neovim.packages;
      };
      modules =
        # Infrastructure and shared policy.
        [
          # Opinionated nix daemon settings from Determinate Systems.
          determinate.nixosModules.default

          sops-nix.nixosModules.sops

          # Host-specific config: bootloader, hostname, timezone, stateVersion, hardware.
          ../hosts/${hostname}

          # Shared baseline: nix settings, locale, base packages, root ssh, zsh, root key.
          ../modules/common.nix

          # Automatic nightly pull and platform-specific rebuild. Disable per-host
          # with rcfiles_nix.autoUpgrade.enable = false.
          ../modules/auto-upgrade.nix

          # nrs alias wrapping the platform rebuild command. Disable per-host
          # with rcfiles_nix.rebuild.enable = false.
          ../modules/rebuild.nix
        ]
        # User layer — two separate systems that both iterate over `users`, but
        # operate in different module systems and own different concerns.
        #
        # 1. System modules (NixOS module system): define WHO the user IS —
        #    account, shell, group membership, uid. These set users.users.<name>
        #    options and must exist at the OS level.
        ++ builtins.concatMap (userModules {inherit isDarwin;}) users
        # 2. Home Manager (HM subsystem): defines WHAT the user's environment
        #    LOOKS LIKE — dotfiles, user packages, ~/.config. Evaluated by HM's
        #    own module system inside the home-manager NixOS module, not by the
        #    NixOS option evaluator directly.
        ++ [
          home-manager-module
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [sops-nix.homeManagerModules.sops];
            # stateVersion flows into every user's home config from the single mkHost param.
            # rcfilesSrc/rcfilesRev seed ~/rcfiles-nix on first activation from the Nix closure.
            home-manager.extraSpecialArgs = {
              inherit stateVersion;
              # Attrset of flake-pinned tmux plugin sources passed to users/brpol/home/tmux.nix.
              # Add new plugins here and as flake inputs; flake.lock tracks the hashes.
              tmuxExtraPlugins = {inherit tmux-menus tmux-easy-motion;};
              rcfilesSrc = self.outPath;
              rcfilesRev = self.rev or null;
            };
            # Each user gets their own users/<name>/home/ directory as their HM config,
            # plus any per-host overrides under hosts/<hostname>/home-overrides/<user>/.
            home-manager.users = lib.genAttrs users (user: {
              imports =
                [../users/${user}/home]
                ++ hostHomeOverrides {inherit hostname user;};
            });
          }

          # Per-user SSH authorized keys, injected here so user modules stay key-agnostic.
          {
            users.users =
              lib.mapAttrs (_user: keys: {
                openssh.authorizedKeys.keys = keys;
              })
              mergedUserKeys;
          }
        ]
        ++ lib.optional isDarwin ../modules/darwin.nix
        ++ lib.optional (!isDarwin) ../modules/nixos.nix
        ++ lib.optional enableDesktop ../modules/desktop.nix
        ++ lib.optional enableSteam ../modules/steam.nix;
    }
