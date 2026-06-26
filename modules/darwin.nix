{...}: {
  # Mirror of modules/nixos.nix's programs.nh.clean. nix-darwin implements
  # nix.gc with a launchd agent; --keep-since is an nh-specific flag so we
  # use the equivalent nix-collect-garbage flag instead.
  nix.gc = {
    # This will run weekly plus some off to rotate throughout the week by default
    automatic = true;
    options = "--delete-older-than 7d";
  };
}
