{
  config,
  lib,
  pkgs,
  ...
}: let
  driveNames = [
    "personal"
    "tokyorust"
    "univalent"
  ];

  secretName = drive: field: "brpol/google-drive/${drive}/${field}";
  secretNames =
    lib.concatMap
    (drive: map (secretName drive) ["client_id" "client_secret" "token"])
    driveNames;

  mountPoint = drive: "${config.home.homeDirectory}/mnt/gdrive/${drive}";
  cacheDir = drive: "${config.xdg.cacheHome}/rclone/google-drive/${drive}";
  templateName = drive: "rclone-google-drive-${drive}.conf";
  configFile = drive: config.sops.templates.${templateName drive}.path;

  cleanupMount = drive:
    pkgs.writeShellApplication {
      name = "cleanup-rclone-google-drive-${drive}";
      runtimeInputs = [pkgs.util-linux];
      text = ''
        if mountpoint -q ${lib.escapeShellArg (mountPoint drive)}; then
          /run/wrappers/bin/fusermount3 -uz ${lib.escapeShellArg (mountPoint drive)} || true
        fi
      '';
    };

  mountService = drive: {
    Unit = {
      Description = "rclone Google Drive mount (${drive})";
      After = ["sops-nix.service"];
      Requires = ["sops-nix.service"];
      PartOf = ["sops-nix.service"];
    };

    Service = {
      Type = "notify";
      Environment = [
        "PATH=/run/wrappers/bin:${lib.makeBinPath [pkgs.fuse3 pkgs.coreutils]}"
      ];
      # rclone refuses to mount onto a missing directory; the cache dir is
      # created up front so both live under a 0700 tree.
      ExecStartPre = "${lib.getExe' pkgs.coreutils "install"} -d -m 0700 ${lib.escapeShellArg (mountPoint drive)} ${lib.escapeShellArg (cacheDir drive)}";
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe pkgs.rclone)
        "mount"
        "google-drive:"
        (mountPoint drive)
        "--config"
        (configFile drive)
        "--cache-dir"
        (cacheDir drive)
        "--vfs-cache-mode"
        "writes"
        "--vfs-cache-max-size"
        "10Gi"
        "--umask"
        "077"
      ];
      ExecStopPost = lib.getExe (cleanupMount drive);
      Restart = "on-failure";
      RestartSec = "10s";
      TimeoutStopSec = "30s";
    };

    Install.WantedBy = ["default.target"];
  };
in {
  config = lib.mkIf pkgs.stdenv.isLinux {
    sops.secrets = lib.genAttrs secretNames (_: {});

    # rclone.conf is rendered from secrets by sops-nix (never staged in the Nix
    # store). The token JSON must be a single-line YAML string in secrets.yaml.
    sops.templates = lib.listToAttrs (map (drive:
      lib.nameValuePair (templateName drive) {
        content = ''
          [google-drive]
          type = drive
          client_id = ${config.sops.placeholder.${secretName drive "client_id"}}
          client_secret = ${config.sops.placeholder.${secretName drive "client_secret"}}
          token = ${config.sops.placeholder.${secretName drive "token"}}
        '';
      })
    driveNames);

    home.packages = [pkgs.rclone];

    systemd.user.services = lib.listToAttrs (map (drive:
      lib.nameValuePair "rclone-google-drive-${drive}" (mountService drive))
    driveNames);
  };
}
