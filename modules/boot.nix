# Shared GRUB settings for all NixOS hosts.
# Host-specific settings (e.g. device) stay in hosts/<name>/default.nix.
{grubTheme, ...}: {
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
    theme = grubTheme;
  };
}
