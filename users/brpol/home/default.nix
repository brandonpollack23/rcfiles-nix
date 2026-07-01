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
  rcfiles = import ../../../lib/rcfiles.nix;

  # Desktop notification at graphical login if the personal age key is absent.
  ageKeyMissingNotify = pkgs.makeDesktopItem {
    name = "age-key-missing-notify";
    desktopName = "Age Key Missing Notify";
    exec = pkgs.writeShellScript "age-key-missing-notify" ''
      [ -f "$HOME/.config/sops/age/keys.txt" ] && exit 0
      ${pkgs.noti}/bin/noti -t "Age Key Missing" \
        -m "Run ensure-age-key to fetch from Bitwarden"
    '';
    # GNOME reads this to decide whether to run the entry at login.
    extraConfig."X-GNOME-Autostart-enabled" = "true";
  };
in {
  imports = [
    ./scripts
    ./secrets.nix
    ./rclone.nix
    ./rust.nix
    ./git.nix
    ./jj.nix
    ./zsh
    ./tmux.nix
    ./timewarrior.nix
    ./vscode.nix
    ./nvim.nix
    ./gnome.nix
  ];

  home.username = "brpol";
  home.homeDirectory =
    if pkgs.stdenv.isDarwin
    then "/Users/brpol"
    else "/home/brpol";

  # Passed in from mkHost via home-manager.extraSpecialArgs — single source of truth.
  home.stateVersion = stateVersion;

  # XDG autostart is Linux-only; on Darwin the zsh warning path in secrets.nix
  # covers the missing age key case.
  xdg.autostart = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    entries = ["${ageKeyMissingNotify}/share/applications/age-key-missing-notify.desktop"];
  };

  # Seed ~/rcfiles-nix on a fresh machine.
  # The working tree is baked into the Nix closure via inputs.self (rcfilesSrc), so no
  # network access is needed for the files themselves. A jj git fetch is attempted
  # afterward to populate full history; it is tolerated if offline at first boot.
  # brpol-setup switches the remote from HTTPS to SSH after credentials are available.
  home.activation.cloneRcfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    _flake_path=''${NH_FLAKE:-$HOME/${rcfiles.checkoutDir}}

    # Validate the target before doing anything destructive (rm -rf below).
    case "$_flake_path" in
      /*) ;;
      *)
        echo "cloneRcfiles: refusing to seed non-absolute path: $_flake_path" >&2
        exit 1
        ;;
    esac

    if [ ! -d "$_flake_path/.jj" ]; then
      ${
      if rcfilesSrc != null
      then ''
        ${lib.getExe seed-rcfiles-from-nix-store} "$_flake_path" "${rcfilesSrc}"
        if ${lib.getExe pkgs.jujutsu} -R "$_flake_path" git fetch 2>/dev/null; then
          ${
          if rcfilesRev != null
          then ''            ${lib.getExe pkgs.jujutsu} -R "$_flake_path" edit "${rcfilesRev}" 2>/dev/null \
                              || ${lib.getExe pkgs.jujutsu} -R "$_flake_path" edit "master@origin" 2>/dev/null \
                              || true''
          else ''${lib.getExe pkgs.jujutsu} -R "$_flake_path" edit "master@origin" 2>/dev/null || true''
        }
        else
          # Offline first activation: the seed left an initialized-but-historyless
          # jj repo. Drop both .jj and .git — keeping the seeded working files —
          # so a later online activation re-enters this block and retries the fetch
          # instead of seeing .jj and skipping forever.
          ${pkgs.coreutils}/bin/rm -rf "$_flake_path/.jj" "$_flake_path/.git"
        fi
      ''
      else ''
        ${lib.getExe pkgs.jujutsu} git clone \
          ${lib.escapeShellArg rcfiles.repoUrl} \
          "$_flake_path"
      ''
    }
    fi
    unset _flake_path
  '';

  # Lets home-manager manage itself; required when using the NixOS module.
  programs.home-manager.enable = true;
}
