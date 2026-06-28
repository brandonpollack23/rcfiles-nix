# Neovim is installed system-wide via modules/common.nix (nightly overlay).
# This module creates a mutable out-of-store symlink so lazy/mason can write
# back into the working tree and their lockfiles stay version-controlled here.
{
  config,
  pkgs,
  ...
}: {
  # Runtime tools the custom Neovim config shells out to (DAP, formatters, …).
  home.packages = [
    pkgs.gdb # nvim-dap C/C++/Rust debugging
    pkgs.djlint # HTML/Django/Jinja template linter+formatter
  ];

  xdg.configFile."nvim" = {
    # mkOutOfStoreSymlink targets the live working tree, not a read-only store path,
    # so neovim plugins and mason can write files back into the repo.
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/rcfiles-nix/users/brpol/home/nvim";
    recursive = false;
  };
}
