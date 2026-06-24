{
  lib,
  isDarwin,
  ...
}: {
  imports = [
    ./rebuild/${
      if isDarwin
      then "darwin.nix"
      else "nixos.nix"
    }
  ];

  options.rcfiles_nix.rebuild = {
    script = lib.mkOption {
      type = lib.types.package;
      description = "Script wrapping the platform rebuild command; clears the auto-upgrade failure marker on success.";
    };
  };
}
