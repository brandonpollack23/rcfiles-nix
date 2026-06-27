{lib}:
# Per-host Home Manager overrides, matched by user name.
#
# Returns the list of override modules under
# hosts/<hostname>/home-overrides/<user>/ for one host + user. Each *.nix file
# there is merged into that user's Home Manager config, letting a file like
# hosts/ncc1701e/home-overrides/brpol/git.nix layer machine-specific settings on
# top of users/brpol/home/git.nix. Returns [] when the directory is absent, so a
# host opts in just by creating it.
{
  hostname,
  user,
}: let
  dir = ../hosts + "/${hostname}/home-overrides/${user}";
in
  if builtins.pathExists dir
  then
    lib.trivial.pipe (builtins.readDir dir) [
      (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name))
      (lib.mapAttrsToList (name: _: dir + "/${name}"))
    ]
  else []
