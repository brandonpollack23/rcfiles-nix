# Darwin-only configuration imported for every Darwin host via mkHost.
# Mirror of modules/nixos — put Darwin-specific shared policy here.
{...}: {
  imports = [
    ./ssh.nix
    ./sudo.nix
    ./programs-nh.nix
    ./system-defaults.nix
    ./homebrew.nix
  ];

  # Determinate Nix manages gc on Darwin; nix.gc is not needed here.
}
