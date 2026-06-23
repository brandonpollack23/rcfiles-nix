# Home-manager config for brpol.
# This directory is the entry point; split into sub-files and import them here
# as the config grows (e.g. ./shell.nix, ./git.nix, ./neovim.nix).
{
  config,
  pkgs,
  stateVersion,
  ...
}: {
  home.username = "brpol";
  home.homeDirectory = "/home/brpol";

  # Passed in from mkHost via home-manager.extraSpecialArgs — single source of truth.
  home.stateVersion = stateVersion;

  # Lets home-manager manage itself; required when using the NixOS module.
  programs.home-manager.enable = true;
}
