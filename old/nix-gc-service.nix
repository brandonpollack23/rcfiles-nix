# This file is not imported anywhere.  It exists for reference only of dormant/past configs in case they need to be resurrected.
{
  # replaced by programs.nh.clean in modules/nixos.nix.
  #
  # programs.nh.clean runs `nh clean` on a systemd timer, which wraps
  # nix-collect-garbage with profile-aware pruning and is equivalent to
  # the nix.gc setup below.  The old timer fired at 00:03:30 daily and
  # deleted everything older than 7 days; programs.nh.clean is configured
  # with `--keep-since 7d` to match.
  nix.gc = {
    automatic = true;
    dates = "*-*-* 00:03:30";
    options = "--delete-older-than 7d";
  };
}
