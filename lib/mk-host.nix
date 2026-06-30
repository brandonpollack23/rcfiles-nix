{
  lib,
  home-manager,
  determinate,
  packageFlakes,
  sops-nix,
  tmux-menus,
  tmux-easy-motion,
  darwin ? null,
  nix-homebrew ? null,
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
    extraApplications ? [], # optional packages from modules/extra-applications.nix
    enableSteam ? false, # whether or not to enable steam
    users ? ["brpol"], # list of usernames; each must have users/<name>/nixos.nix + home/
    rootAuthorizedKeys ? [], # SSH public keys granted access to root on this host (escape hatch)
    userAuthorizedKeys ? {}, # attrset of username -> SSH public keys (escape hatch)
    allowedSSHHosts ? [], # hostnames whose registered user.pub may SSH in as root + every user
    hostUserKeys ? {}, # registry passed in from flake.nix: hostname -> pubkey or null
  }: let
    allowedKeys = resolveHostKeys {inherit hostname allowedSSHHosts hostUserKeys;};
    # Dedupe so a key granted both as an explicit escape-hatch key and via the
    # allow-list isn't written twice into authorized_keys.
    finalRootKeys = lib.unique (rootAuthorizedKeys ++ allowedKeys);
    # Give every user on this host the same set of allow-list keys. (for now, this can be modified to use the param)
    allowedKeysByUser = lib.genAttrs users (_: allowedKeys);
    # Merge the escape-hatch per-user keys with the allow-list keys, concatenating
    # the two lists when the same username appears in both attrsets, then deduping.
    mergedUserKeys =
      lib.mapAttrs (_: lib.unique)
      (lib.zipAttrsWith (_: lib.concatLists) [
        userAuthorizedKeys
        allowedKeysByUser
      ]);

    # Usernames referenced in userAuthorizedKeys that aren't actually deployed on
    # this host — almost always a typo that would silently grant no access.
    unknownKeyUsers = lib.subtractLists users (lib.attrNames userAuthorizedKeys);

    nixSystem =
      if isDarwin
      then darwin.lib.darwinSystem
      else lib.nixosSystem;

    # Infrastructure modules that differ by platform. Grouped in one place so the
    # NixOS/Darwin split lives in a single conditional rather than being scattered.
    platformModules =
      if isDarwin
      then {
        determinate = determinate.darwinModules.default;
        sops = sops-nix.darwinModules.sops;
        homeManager = home-manager.darwinModules.home-manager;
        homebrew = nix-homebrew.darwinModules.nix-homebrew;
      }
      else {
        determinate = determinate.nixosModules.default;
        sops = sops-nix.nixosModules.sops;
        homeManager = home-manager.nixosModules.home-manager;
      };

    # Keep fast-moving packages and overlays together. Neovim exposes packages
    # directly; Claude Code exposes an overlay.
    flakeOverlays = [
      packageFlakes.claude-code.overlays.default
    ];
  in
    assert lib.assertMsg (users != [])
    "mkHost (${hostname}): `users` must be non-empty — every host needs at least one account.";
    assert lib.assertMsg (!isDarwin || darwin != null)
    "mkHost (${hostname}): isDarwin = true requires a real `darwin` flake input, but none is wired in.";
    assert lib.assertMsg (unknownKeyUsers == [])
    "mkHost (${hostname}): userAuthorizedKeys references users not in `users` (${lib.concatStringsSep ", " unknownKeyUsers}); known users: ${lib.concatStringsSep ", " users}.";
      nixSystem {
        specialArgs = {
          inherit hostname stateVersion isDarwin enableSteam extraApplications;
          rootAuthorizedKeys = finalRootKeys;
        };
        modules =
          # Infrastructure and shared policy.
          [
            # Opinionated nix daemon settings from Determinate Systems.
            platformModules.determinate

            platformModules.sops

            (
              {pkgs, ...}: {
                nixpkgs.overlays = flakeOverlays;
                environment.systemPackages = [
                  pkgs.codex
                  pkgs.claude-code
                  packageFlakes.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
                ];
              }
            )
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
            platformModules.homeManager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "home-manager-backup";
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
          ++ lib.optionals isDarwin [platformModules.homebrew ../modules/darwin.nix]
          ++ lib.optional (!isDarwin) ../modules/nixos.nix
          # desktop.nix and steam.nix are NixOS-only modules (services.xserver,
          # programs.steam); never import them on Darwin.
          ++ lib.optional (enableDesktop && !isDarwin) ../modules/desktop.nix
          ++ lib.optional (extraApplications != []) ../modules/extra-applications.nix
          ++ lib.optional (enableSteam && !isDarwin) ../modules/steam.nix;
      }
