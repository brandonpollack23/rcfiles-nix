# programs.timewarrior does not exist in the pinned HM revision; use xdg.configFile.
{
  config,
  pkgs,
  ...
}: {
  # This module owns the timewarrior tracker and its sync client.
  home.packages = [pkgs.timewarrior pkgs.timew-sync-client];

  xdg.configFile = {
    # Minimal main config: one report tweak plus an import of the active theme,
    # following timewarrior's documented theme mechanism (import <path>).
    "timewarrior/timewarrior.cfg".text = ''
      reports.summary.ids = yes

      import ${config.xdg.configHome}/timewarrior/darcula.theme
    '';

    # Active custom theme (imported above).
    "timewarrior/darcula.theme".source = ./timewarrior/darcula.theme;

    # Bundled upstream themes, kept as optional alternatives — switch by changing
    # the import line in timewarrior.cfg.
    "timewarrior/dark.theme".source = ./timewarrior/dark.theme;
    "timewarrior/dark_blue.theme".source = ./timewarrior/dark_blue.theme;
    "timewarrior/dark_green.theme".source = ./timewarrior/dark_green.theme;
    "timewarrior/dark_red.theme".source = ./timewarrior/dark_red.theme;
  };
}
