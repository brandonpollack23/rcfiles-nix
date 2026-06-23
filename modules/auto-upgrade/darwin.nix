# Pulls the latest rcfiles-nix checkout and rebuilds nix-darwin at 3 AM.
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.rcfiles.autoUpgrade;
  flakePath = lib.escapeShellArg cfg.flakePath;
in {
  config = lib.mkIf cfg.enable {
    launchd.daemons.rcfiles-auto-upgrade = {
      path = with pkgs; [
        git
        nix
        coreutils
        gnutar
        gzip
        xz
        openssh
        "/run/current-system/sw/bin"
      ];
      environment.HOME = "/var/root";
      script = ''
        git -c safe.directory=${flakePath} -C ${flakePath} pull --rebase
        darwin-rebuild switch --flake ${flakePath}
      '';
      serviceConfig = {
        StartCalendarInterval = [
          {
            Hour = 3;
            Minute = 0;
          }
        ];
        StandardOutPath = "/var/log/rcfiles-auto-upgrade.log";
        StandardErrorPath = "/var/log/rcfiles-auto-upgrade.log";
      };
    };
  };
}
