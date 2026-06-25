# Baseline configuration imported by every host via mkHost.
# Put things here if they should be true on every machine you own.
{
  pkgs,
  config,
  neovimPkg,
  nixosCliPkg,
  ...
}: {
  imports = [
    ./common/nix-daemon.nix
    ./common/secrets.nix
    ./common/i18n.nix
    ./common/ssh.nix
  ];

  # Base CLI tools available on every host. GUI apps belong in modules/desktop.nix.
  environment.systemPackages = with pkgs;
    [
      alejandra # nix code formatter
      bat # cat with wings
      bitwarden-cli
      cachix # nix caching system
      curl
      fastfetch
      fh # flakehub
      fzf
      gh # UI to a bad forge
      git
      htop
      jj # version control of the modern times, reminds me of fig
      jq
      noti # xplatform notifications tool
      ripgrep
      sops # Secret operations.  Uses age keys to encrypt and decrypte files, opening them in default editor.
      ssh-to-age # utility to convert ssh keys to age keys, used by sops for secrets management in nix
      timew-sync-client
      timewarrior # time tracker
      tmux
      tree
      wget
      zsh
    ]
    ++ [
      neovimPkg.${pkgs.stdenv.hostPlatform.system}.default # nightly neovim
      nixosCliPkg.${pkgs.stdenv.hostPlatform.system}.default # nixos CLI tool
    ];

  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=120
  '';

  environment.variables.EDITOR = "nvim";
  environment.shellAliases.nrs = "${config.rcfiles_nix.rebuild.script}";

  # zsh.enable makes zsh available as a login shell system-wide; individual
  # users opt in by setting shell = pkgs.zsh (or bashInteractive) in their nixos.nix.
  programs.zsh.enable = true;
}
