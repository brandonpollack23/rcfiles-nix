# To add a new host/machine, create hosts/<name>/{meta,default,hardware-configuration}.nix.
# flake.nix auto-discovers every hosts/<name>/ that contains a meta.nix — no manual list.
{
  nixpkgs,
  home-manager,
  determinate,
  neovim,
  claude-code,
  sops-nix,
  tmux-menus,
  tmux-easy-motion,
  darwin ? null,
  nix-homebrew ? null,
  self,
  ...
}: let
  packageFlakes = {
    inherit neovim claude-code;
  };
in {
  # mk-host imports the lib helpers it needs (resolveHostKeys, hostHomeOverrides)
  # directly and builds its own myLib namespace; they don't need to be threaded
  # through here.
  mkHost = import ./mk-host.nix {
    lib = nixpkgs.lib;
    inherit home-manager determinate packageFlakes sops-nix darwin nix-homebrew self tmux-menus tmux-easy-motion;
  };
}
