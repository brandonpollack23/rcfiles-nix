# To add a new host/machine, add an entry to hostConfigs in flake.nix — the key becomes hostname.
{
  nixpkgs,
  home-manager,
  determinate,
  neovim,
  nixos-cli,
  sops-nix,
  tmux-menus,
  tmux-easy-motion,
  darwin ? null,
  self,
  ...
}: {
  # mk-host imports the lib helpers it needs (resolveHostKeys, hostHomeOverrides)
  # directly and builds its own myLib namespace; they don't need to be threaded
  # through here.
  mkHost = import ./mk-host.nix {
    lib = nixpkgs.lib;
    inherit home-manager determinate neovim nixos-cli sops-nix darwin self tmux-menus tmux-easy-motion;
  };
}
