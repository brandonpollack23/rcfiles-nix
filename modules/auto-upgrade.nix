{
  lib,
  config,
  isDarwin,
  ...
}: let
  rcfiles = import ../lib/rcfiles.nix;
in {
  imports = [
    ./auto-upgrade/${
      if isDarwin
      then "darwin.nix"
      else "nixos.nix"
    }
  ];

  options.rcfiles_nix.autoUpgrade = {
    enable = lib.mkEnableOption "automatic pull and rebuild from GitHub" // {default = true;};

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.users.users.brpol.home}/.local/state/rcfiles-auto-upgrade";
      description = "Directory for persisting upgrade failure markers.";
    };

    # Repository/checkout constants shared by the NixOS and Darwin auto-upgrade
    # implementations; defaults come from lib/rcfiles.nix.
    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "${config.users.users.brpol.home}/${rcfiles.checkoutDir}";
      description = "Absolute path to the rcfiles-nix checkout that is pulled and rebuilt.";
    };

    repoUrl = lib.mkOption {
      type = lib.types.str;
      default = rcfiles.repoUrl;
      description = "HTTPS remote pulled by the auto-upgrade service (no SSH key required).";
    };
  };
}
