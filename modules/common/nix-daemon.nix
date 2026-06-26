{
  pkgs,
  config,
  ...
}: {
  nix = {
    settings = {
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://watersucks.cachix.org"
        "https://brandonpollack23.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "watersucks.cachix.org-1:6gadPC5R8iLWQ3EUtfu3GFrVY7X6I4Fwz/ihW25Jbv8="
        "brandonpollack23.cachix.org-1:Sp+6/7oI23QPPUBx+a5Kuv1r4WaqTrEIJ/FBQ3CkVUY="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      post-build-hook = pkgs.writeShellScript "cachix-push" ''
        set -eu
        set -f
        export IFS=' '
        export CACHIX_AUTH_TOKEN="$(cat ${config.sops.secrets.cachix-brandonpollack23.path})"
        exec ${pkgs.cachix}/bin/cachix push brandonpollack23 $OUT_PATHS
      '';
    };
    optimise.automatic = true;
    # gc is handled by nh
  };

  nixpkgs.config.allowUnfree = true;
}
