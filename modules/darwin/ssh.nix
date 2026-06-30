# Enable the system SSH daemon (Remote Login) so a host ed25519 key is generated.
# The host key is used as the sops-nix age decryption identity for system secrets.
{...}: {
  services.openssh.enable = true;
}
