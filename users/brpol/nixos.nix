# NixOS-specific system-level config for brpol.
# Loaded alongside default.nix on NixOS hosts only.
#
# This is a NixOS module — the same top-level option namespace as configuration.nix.
# Use it for anything that only exists on NixOS: services.*, systemd.*, networking.*, etc.
# Cross-platform user identity (users.users.<name>) belongs in default.nix instead.
#
# Example:
# { pkgs, ... }: {
#   services.gpg-agent = {
#     enable = true;
#     pinentryPackage = pkgs.pinentry-curses;
#   };
#
#   systemd.user.services.my-service = {
#     description = "My custom user service";
#     wantedBy = [ "default.target" ];
#     serviceConfig.ExecStart = "${pkgs.my-tool}/bin/my-tool";
#   };
# }
{...}: {}
