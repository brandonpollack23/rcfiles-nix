# Home-manager config for brpol.
# This directory is the entry point; split into sub-files and import them here
# as the config grows (e.g. ./shell.nix, ./git.nix, ./neovim.nix).
{
  pkgs,
  lib,
  stateVersion,
  ...
}: {
  imports = [./scripts];

  home.username = "brpol";
  home.homeDirectory = "/home/brpol";

  # Passed in from mkHost via home-manager.extraSpecialArgs — single source of truth.
  home.stateVersion = stateVersion;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Desktop notification at graphical login if age key is absent.
  # XDG autostart is used instead of a systemd user service because Cinnamon+LightDM
  # does not reliably activate graphical-session.target for systemd user services.
  xdg.configFile."autostart/age-key-missing-notify.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Age Key Missing Notify
    Exec=${pkgs.writeShellScript "age-key-missing-notify" ''
      [ -f "$HOME/.config/sops/age/keys.txt" ] && exit 0
      ${pkgs.noti}/bin/noti -t "Age Key Missing" \
        -m "Run ensure-age-key to fetch from Bitwarden"
    ''}
    Hidden=false
    X-GNOME-Autostart-enabled=true
  '';

  # Clone rcfiles-nix if it doesn't exist yet (e.g. on a fresh machine).
  # HTTPS is used so no SSH key is required; brpol-setup switches the remote to SSH.
  home.activation.cloneRcfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    _flake_path=''${NH_FLAKE:-$HOME/rcfiles-nix}
    if [ ! -d "$_flake_path/.git" ]; then
      ${pkgs.git}/bin/git clone \
        https://github.com/brandonpollack23/rcfiles-nix.git \
        "$_flake_path"
    fi
    unset _flake_path
  '';

  # Lets home-manager manage itself; required when using the NixOS module.
  programs.home-manager.enable = true;
}
