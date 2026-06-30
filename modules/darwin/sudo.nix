# Touch ID for sudo; the macOS analog of the NixOS sudo timeout tweak.
{...}: {
  security.pam.services.sudo_local.touchIdAuth = true;
}
