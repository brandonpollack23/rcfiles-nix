# Brandon Pollack Nix Config

- do run nix flake check when finished
- do prefer flakes to overlays
- do attempt to lookup if a flake uses caches and implement them, but ask and try to verify credibility
- do format Nix files with `alejandra` (it is in `environment.systemPackages`)

## Architecture conventions

- GUI/desktop packages belong in `modules/desktop.nix`; CLI tools belong in `modules/common.nix`
- Packages from flake inputs (e.g. neovim, nixos-cli) belong in `lib/default.nix` — modules must not reach into flake inputs directly
- User system-level config goes in `users/<name>/nixos.nix` (or `darwin.nix`); home-manager config goes under `users/<name>/home/`
- Desktop support is gated by `enableDesktop` in `mkHost`; set it per-host in `flake.nix`

## Darwin / cross-platform

- Darwin support is stubbed and dormant but must stay working — changes must not break the `isDarwin = true` path in `lib/default.nix`
