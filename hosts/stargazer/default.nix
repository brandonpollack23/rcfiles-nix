{hostname, ...}: {
  networking.hostName = hostname; # "stargazer"
  networking.computerName = "Stargazer-II";
  time.timeZone = "Asia/Tokyo";
  # nix-darwin uses an integer stateVersion, separate from the "26.05" string in
  # meta.nix (which feeds home.stateVersion). Verify against current nix-darwin
  # release notes before first activation.
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";
  # Required by nix-darwin ≥ 25 for homebrew, system.defaults, and launchd user agents.
  system.primaryUser = "brpol";
}
