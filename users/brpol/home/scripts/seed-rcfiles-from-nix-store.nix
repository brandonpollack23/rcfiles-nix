{pkgs}: let
  rcfiles = import ../../../../lib/rcfiles.nix;
in
  pkgs.writeShellApplication {
    name = "seed-rcfiles-from-nix-store";
    runtimeInputs = [pkgs.rsync pkgs.git];
    # The git remote URL is injected, not hard-coded in the script.
    runtimeEnv = {RCFILES_REPO_URL = rcfiles.repoUrl;};
    text = builtins.readFile ./seed-rcfiles-from-nix-store.sh;
  }
