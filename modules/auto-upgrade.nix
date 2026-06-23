{
  lib,
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

  options.rcfiles.autoUpgrade = {
    enable = lib.mkEnableOption "automatic pull and rebuild from GitHub" // {default = true;};

    flakePath = lib.mkOption {
      type = lib.types.str;
      default =
        if isDarwin
        then "/Users/brpol/rcfiles-nix"
        else "/home/brpol/rcfiles-nix";
      description = "Path to the rcfiles-nix checkout to update and rebuild.";
    };
  };
}
