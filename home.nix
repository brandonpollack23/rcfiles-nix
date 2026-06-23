{
  config,
  pkgs,
  ...
}: {
  home.username = "brpol";
  home.homeDirectory = "/home/brpol";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
