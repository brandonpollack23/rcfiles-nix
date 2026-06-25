let
  ncc1701eKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ+LxALPXfkVQ3MxQu3h0pkZ3o+OtY5cSfFgf5lkTlD0 brpol@ncc-1701e";
in {
  stateVersion = "26.05";
  enableDesktop = true;
  users = ["brpol"];
  rootAuthorizedKeys = [ncc1701eKey];
  userAuthorizedKeys = {
    brpol = [ncc1701eKey];
  };
  grubTheme = ../../grub-themes/fallout;
}
