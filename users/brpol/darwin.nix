# Darwin-specific system-level config for brpol.
# Loaded alongside default.nix on Darwin (macOS) hosts only.
#
# This is a nix-darwin module — the same top-level option namespace as darwin-configuration.nix.
# Use it for anything that only exists on Darwin: system.defaults.*, launchd.*, homebrew.*, etc.
# Cross-platform user identity (users.users.<name>) belongs in default.nix instead.
#
# Example:
# { pkgs, ... }: {
#   system.defaults.dock.autohide = true;
#
#   launchd.user.agents.my-agent = {
#     serviceConfig.ProgramArguments = [ "${pkgs.my-tool}/bin/my-tool" ];
#     serviceConfig.RunAtLoad = true;
#   };
# }
{}
