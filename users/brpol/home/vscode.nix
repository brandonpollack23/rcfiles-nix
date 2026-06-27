# VSCode package is installed system-wide in modules/desktop.nix.
# This module enables programs.vscode with mutable extensions so that
# Settings Sync can own extensions, settings, and keybindings after sign-in.
{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = true;
  };
}
