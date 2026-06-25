# Enable running dynamically linked executables not built for NixOS.
# nix-ld provides the ELF interpreter; envfs exposes PATH binaries under
# /usr/bin and /bin so shebangs like #!/usr/bin/env bash work for foreign apps.
{
  lib,
  isDarwin,
  ...
}:
lib.mkIf (!isDarwin) {
  programs.nix-ld.enable = true;
  services.envfs.enable = true;
}
