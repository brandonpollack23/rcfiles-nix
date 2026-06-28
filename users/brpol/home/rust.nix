{
  config,
  lib,
  pkgs,
  ...
}: let
  cargoTokenPath = config.sops.secrets."brpol/cargo-registry-token".path;
  cargoTokenProvider = pkgs.writeShellApplication {
    name = "cargo-token-from-sops";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      cat ${lib.escapeShellArg cargoTokenPath}
    '';
  };

  tomlFormat = pkgs.formats.toml {};
in {
  # This token is for crates.io, whose credential provider is configured under
  # [registry] below. To add another token, declare another sops secret and a
  # provider script that reads its path, following the definitions above.
  sops.secrets."brpol/cargo-registry-token" = {};

  # crates.io (the default registry) credential provider. The value is a command
  # array: cargo:token-from-stdout runs the given program and reads the token from
  # its stdout (Cargo Book — Registry Authentication). For a named registry, add
  # registries.<name>.{index,credential-provider} to the attrset below.
  home.file.".cargo/config.toml".source = tomlFormat.generate "cargo-config.toml" {
    registry.credential-provider = [
      "cargo:token-from-stdout"
      "${lib.getExe cargoTokenProvider}"
    ];
  };
}
