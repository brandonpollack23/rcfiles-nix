# programs.timewarrior does not exist in the pinned HM revision; use xdg.configFile.
{...}: {
  xdg.configFile = {
    "timewarrior/timewarrior.cfg".text = ''
      reports.summary.ids = yes

      define theme:
        description = "darcula.theme: A theme inspired by the JetBrains Darcula IDE color scheme."
        colors:
          exclusion = "gray10 on gray3"
          today     = "white on gray6"
          holiday   = "rgb424"
          label     = "gray18"
          ids       = "rgb542"
          debug     = "rgb244"

        palette:
          color01 = "white on rgb420"
          color02 = "white on rgb231"
          color03 = "black on rgb542"
          color04 = "white on rgb324"
          color05 = "white on rgb245"
          color06 = "white on rgb411"
          color07 = "white on gray8"
          color08 = "white on rgb531"
          color09 = "white on rgb242"
          color10 = "white on rgb435"
          color11 = "white on rgb134"
          color12 = "white on rgb522"
          color13 = "white on rgb244"
          color14 = "black on rgb443"
          color15 = "white on rgb322"
    '';

    "timewarrior/dark.theme".source = ./timewarrior/dark.theme;
    "timewarrior/dark_blue.theme".source = ./timewarrior/dark_blue.theme;
    "timewarrior/dark_green.theme".source = ./timewarrior/dark_green.theme;
    "timewarrior/dark_red.theme".source = ./timewarrior/dark_red.theme;
  };
}
