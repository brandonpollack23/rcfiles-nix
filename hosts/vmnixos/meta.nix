{
  stateVersion = "26.05";
  enableDesktop = true;
  extraApplications = (import ../../lib/application-profiles.nix).defaultWorkstation;
  enableSteam = true;
  users = ["brpol"];
  allowedSSHHosts = ["ncc1701e"];
}
