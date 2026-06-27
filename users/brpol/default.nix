# Cross-platform system-level user definition for brpol.
# Loaded on all hosts (NixOS and Darwin). Sets users.users.<name> — the user identity
# options that exist on both platforms: groups, shell, etc.
# SSH authorized keys are injected by mkHost via userAuthorizedKeys, not set here.
# OS-specific system config goes in nixos.nix or darwin.nix.
# Home-manager config (dotfiles, programs, etc.) lives in ./home/.
{pkgs, ...}: {
  users.users."brpol" = {
    isNormalUser = true;
    description = "Brandon Pollack";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };
}
