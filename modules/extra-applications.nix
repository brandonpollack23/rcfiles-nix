# Optional applications selected by name through each host's extraApplications.
{
  config,
  extraApplications,
  isDarwin,
  lib,
  pkgs,
  ...
}: let
  applications = {
    blender = pkgs.blender;
    davinci-resolve-studio = pkgs.davinci-resolve-studio;
    zoom = pkgs.zoom-us;
  };
  unknownApplications =
    lib.subtractLists
    (lib.attrNames applications)
    extraApplications;
  unavailableApplications =
    lib.filter
    (name:
      builtins.hasAttr name applications
      && !lib.meta.availableOn pkgs.stdenv.hostPlatform applications.${name})
    extraApplications;
in
  lib.mkMerge [
    {
      assertions = [
        {
          assertion = unknownApplications == [];
          message = "Unknown extraApplications: ${lib.concatStringsSep ", " unknownApplications}";
        }
        {
          assertion = unavailableApplications == [];
          message = "extraApplications unavailable on ${pkgs.stdenv.hostPlatform.system}: ${lib.concatStringsSep ", " unavailableApplications}";
        }
      ];

      environment.systemPackages =
        map (name: applications.${name})
        (lib.filter (name: builtins.hasAttr name applications) extraApplications);

      # Resolve Studio activation is machine-bound and still happens in the GUI.
      # Keep the activation key out of the Nix store while making it available to
      # the local user for that one-time operation.
      sops.secrets."brpol/davinci-resolve-studio-license-key" = lib.mkIf (lib.elem "davinci-resolve-studio" extraApplications) {
        owner = config.users.users.brpol.name;
      };
    }

    (lib.mkIf (!isDarwin) {
      programs.zoom-us.enable = lib.elem "zoom" extraApplications;
    })
  ]
