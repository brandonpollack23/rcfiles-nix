# VSCode package is installed system-wide in modules/desktop.nix on NixOS.
# Darwin uses the Homebrew cask from modules/darwin/homebrew.nix.
{
  lib,
  pkgs,
  ...
}: {
  programs.vscode = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = true;
  };
}
