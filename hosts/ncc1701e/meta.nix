{
  stateVersion = "26.05";
  enableDesktop = true;
  extraApplications = (import ../../lib/application-profiles.nix).defaultWorkstation;
  enableSteam = true;
  users = ["brpol"];
  # TODO: add stargazer (mac) once Darwin support is active
  allowedSSHHosts = [];
}
