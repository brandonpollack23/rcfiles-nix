# Cross-platform system-level user definition for brpol.
# Loaded on all hosts (NixOS and Darwin). Sets only the users.users.<name>
# fields that mean the same thing on both platforms: description and login shell.
# SSH authorized keys are injected by mkHost via userAuthorizedKeys, not set here.
# Platform-specific account fields (isNormalUser/groups on NixOS, home/account on
# Darwin) live in nixos.nix / darwin.nix.
# Home-manager config (dotfiles, programs, etc.) lives in ./home/.
{pkgs, ...}: {
  users.users."brpol" = {
    description = "Brandon Pollack";
    shell = pkgs.zsh;
  };
}
