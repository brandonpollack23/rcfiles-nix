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
in {
  # This token is for crates.io, whose credential provider is configured under
  # [registry] below. To add another token, declare another sops secret and a
  # provider script that reads its path, following the definitions above.
  sops.secrets."brpol/cargo-registry-token" = {};

  home.file.".cargo/config.toml".text = ''
    [registry]
    credential-provider = ["cargo:token-from-stdout", "${lib.getExe cargoTokenProvider}"]

    # For a named registry, add its index and token-specific provider like this:
    # [registries.example]
    # index = "sparse+https://registry.example/index/"
    # credential-provider = ["cargo:token-from-stdout", "/path/to/its/provider"]
  '';
}
