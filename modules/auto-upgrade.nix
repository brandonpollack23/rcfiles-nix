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

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.users.users.brpol.home}/.local/state/rcfiles-auto-upgrade";
      description = "Directory for persisting upgrade failure markers.";
    };
  };

  config = {
    environment.etc."rcfiles-nix/flake-path" = {
      text = "${config.users.users.brpol.home}/rcfiles-nix\n";
      mode = "0644";
    };
  };
}
