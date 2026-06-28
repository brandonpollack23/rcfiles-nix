{
  config,
  lib,
  ...
}: {
  # ── sops-nix home-manager bootstrap for brpol ───────────────────────────────
  # Infrastructure shared across all of brpol's HM modules that use sops.
  # Program-specific secrets and templates live next to the program (cargo.nix,
  # git.nix, jj.nix, etc.). Multi-consumer / shell-level secrets are declared here.
  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

  # Warns at interactive shell startup if brpol's personal age key (needed to edit
  # secrets and register this machine's key) is not set up yet. Scoped to this
  # user's Home Manager config — no `id -un` guard needed.
  programs.zsh.initContent = lib.mkOrder 1000 ''
    if [ ! -f ${lib.escapeShellArg config.sops.age.keyFile} ]; then
      printf '\033[1;33m\nWARNING: personal age key not found.\033[0m\n'
      printf 'Run \033[1mensure-age-key\033[0m to fetch from Bitwarden,\n'
      printf 'or \033[1medit-nix-secrets\033[0m / \033[1mupdate-secret-keys or brpol-setup\033[0m will do it on demand.\n\n'
    fi
  '';
}
