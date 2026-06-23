# Pulls the latest rcfiles-nix checkout and rebuilds NixOS at 3 AM.
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
    systemd.timers.nixos-auto-upgrade = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
      };
    };

    systemd.services.nixos-auto-upgrade = {
      description = "Pull latest rcfiles-nix and switch NixOS generation";
      restartIfChanged = false;
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig.Type = "oneshot";
      environment.HOME = "/root";
      path = with pkgs; [git nix coreutils gnutar gzip xz openssh];
      script = ''
        git -c safe.directory=${flakePath} -C ${flakePath} pull --rebase
        ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake ${flakePath}
      '';
    };
  };
}
