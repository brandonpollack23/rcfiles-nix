{
  stateVersion = "26.05"; # home.stateVersion (string)
  isDarwin = true;
  enableDesktop = false; # GUI apps via Homebrew casks; desktop.nix is NixOS-only
  enableSteam = false; # Steam via cask; programs.steam is NixOS-only
  extraApplications = [];
  users = ["brpol"];
  allowedSSHHosts = [];
}
