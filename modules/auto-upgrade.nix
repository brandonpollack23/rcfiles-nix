{
  lib,
  config,
  isDarwin,
  ...
}: {
  imports = [
    ./auto-upgrade/${
      if isDarwin
      then "darwin.nix"
      else "nixos.nix"
    }
  ];

  options.rcfiles_nix.autoUpgrade = {
    enable = lib.mkEnableOption "automatic pull and rebuild from GitHub" // {default = true;};

    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "${config.users.users.brpol.home}/rcfiles-nix";
      description = "Path to the rcfiles-nix checkout to update and rebuild.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.users.users.brpol.home}/.local/state/rcfiles-auto-upgrade";
      description = "Directory for persisting upgrade failure markers.";
    };
  };
}
