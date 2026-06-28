# Shared constants describing this rcfiles-nix checkout.
#
# Imported by both NixOS modules (auto-upgrade) and Home Manager modules (home
# bootstrap, setup scripts) so the GitHub remote URLs and the checkout directory
# name have a single source of truth instead of being copied as string literals
# across the tree. The absolute checkout path is derived per-context by joining
# the relevant home directory with checkoutDir.
{
  # HTTPS remote used for unauthenticated pulls (auto-upgrade, first-boot seed).
  repoUrl = "https://github.com/brandonpollack23/rcfiles-nix.git";
  # SSH remote brpol-setup switches to once credentials are available.
  sshUrl = "git@github.com:brandonpollack23/rcfiles-nix.git";
  # Directory name of the checkout under the user's home directory.
  checkoutDir = "rcfiles-nix";
}
