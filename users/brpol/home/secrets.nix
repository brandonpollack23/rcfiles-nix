{config, ...}: {
  # ── sops-nix home-manager bootstrap for brpol ───────────────────────────────
  # Infrastructure shared across all of brpol's HM modules that use sops.
  # Program-specific secrets and templates live next to the program (cargo.nix,
  # git.nix, jj.nix, etc.). Multi-consumer / shell-level secrets are declared here.
  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
}
