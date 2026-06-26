{pkgs}:
pkgs.writeShellApplication {
  name = "seed-rcfiles-from-nix-store";
  runtimeInputs = [pkgs.rsync pkgs.git];
  text = builtins.readFile ./seed-rcfiles-from-nix-store.sh;
}
