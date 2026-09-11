{
  pkgs,
  config,
  isDarwin,
  lib,
  ...
}: let
  cacheSettings = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://brandonpollack23.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "brandonpollack23.cachix.org-1:Sp+6/7oI23QPPUBx+a5Kuv1r4WaqTrEIJ/FBQ3CkVUY="
    ];
    post-build-hook = pkgs.writeShellScript "cachix-push" ''
      set -eu
      set -f
      export IFS=' '
      export CACHIX_AUTH_TOKEN="$(cat ${config.sops.secrets.cachix-brandonpollack23.path})"
      exec ${pkgs.cachix}/bin/cachix push brandonpollack23 $OUT_PATHS
    '';
  };
in
  {
    nix = {
      # Determinate Nix disables nix-darwin's nix.conf writer. Keep these
      # settings here for NixOS and route the Darwin copy below instead.
      settings = lib.mkIf (!isDarwin) (cacheSettings
        // {
          auto-optimise-store = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        });
      optimise.automatic = lib.mkIf (!isDarwin) true;
      # gc is handled by nh (NixOS) or Determinate (Darwin)
    };

    nixpkgs.config.allowUnfree = true;
  }
  // lib.optionalAttrs isDarwin {
    # Determinate renders customSettings to /etc/nix/nix.custom.conf.
    determinateNix.customSettings = cacheSettings;
  }
