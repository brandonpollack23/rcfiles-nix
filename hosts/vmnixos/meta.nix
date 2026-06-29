{
  stateVersion = "26.05";
  enableDesktop = true;
  extraApplications =
    builtins.filter
    (application: application != "davinci-resolve-studio" && application != "blender")
    (import ../../lib/application-profiles.nix).defaultWorkstation;
  enableSteam = true;
  users = ["brpol"];
  allowedSSHHosts = ["ncc1701e"];
}
