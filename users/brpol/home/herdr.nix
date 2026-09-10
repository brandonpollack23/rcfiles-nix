# herdr has no home-manager module, so this creates a mutable out-of-store
# symlink the same way nvim.nix does, letting herdr write plugin state and
# session data back into the working tree.
{config, ...}: {
  xdg.configFile."herdr" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/rcfiles-nix/users/brpol/home/herdr";
    recursive = false;
  };
}
