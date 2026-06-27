# Home-manager config for brpol.
# This directory is the entry point; split into sub-files and import them here
# as the config grows (e.g. ./shell.nix, ./git.nix, ./neovim.nix).
{
  pkgs,
  lib,
  stateVersion,
  rcfilesSrc ? null, # Nix store path of working tree; injected by mkHost
  rcfilesRev ? null, # git SHA of the baked-in revision; null when dirty or standalone HM
  ...
}: let
  seed-rcfiles-from-nix-store = import ./scripts/seed-rcfiles-from-nix-store.nix {inherit pkgs;};
in {
  imports = [
    ./scripts
    ./secrets.nix
    ./rust.nix
    ./git.nix
    ./jj.nix
    ./zsh
    ./tmux.nix
    ./timewarrior.nix
    ./vscode.nix
    ./nvim.nix
  ];

  home.username = "brpol";
  home.homeDirectory = "/home/brpol";

  # Passed in from mkHost via home-manager.extraSpecialArgs — single source of truth.
  home.stateVersion = stateVersion;

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

  # Seed ~/rcfiles-nix on a fresh machine.
  # The working tree is baked into the Nix closure via inputs.self (rcfilesSrc), so no
  # network access is needed for the files themselves. A git fetch is attempted afterward
  # to populate full history; it is tolerated if the machine is offline at first boot.
  # brpol-setup switches the remote from HTTPS to SSH after credentials are available.
  home.activation.cloneRcfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    _flake_path=''${NH_FLAKE:-$HOME/rcfiles-nix}
    if [ ! -d "$_flake_path/.git" ]; then
      ${
      if rcfilesSrc != null
      then ''
        ${seed-rcfiles-from-nix-store}/bin/seed-rcfiles-from-nix-store "$_flake_path" "${rcfilesSrc}"
        if ${pkgs.git}/bin/git -C "$_flake_path" fetch origin 2>/dev/null; then
          ${
          if rcfilesRev != null
          then ''            ${pkgs.git}/bin/git -C "$_flake_path" reset --hard "${rcfilesRev}" 2>/dev/null \
                              || ${pkgs.git}/bin/git -C "$_flake_path" reset --hard origin/HEAD 2>/dev/null \
                              || true''
          else ''${pkgs.git}/bin/git -C "$_flake_path" reset --hard origin/HEAD 2>/dev/null || true''
        }
        fi
      ''
      else ''
        ${pkgs.git}/bin/git clone \
          https://github.com/brandonpollack23/rcfiles-nix.git \
          "$_flake_path"
      ''
    }
    fi
    unset _flake_path
  '';

  # Lets home-manager manage itself; required when using the NixOS module.
  programs.home-manager.enable = true;
}
