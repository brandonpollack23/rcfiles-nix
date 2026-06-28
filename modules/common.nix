# Baseline configuration imported by every host via mkHost.
# Put things here if they should be true on every machine you own.
{
  pkgs,
  lib,
  config,
  neovimPkg,
  ...
}: {
  imports = [
    ./common/nix-daemon.nix
    ./common/nix-ld.nix
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
      chafa # image-to-terminal renderer (used by cati alias)
      cmake
      curl
      difftastic # structural diff tool (used by jj)
      eza # modern ls replacement
      fastfetch
      fh # flakehub
      fzf
      gh # UI to a bad forge
      git
      gnumake # make, need this sometimes
      htop
      jj # version control of the modern times, reminds me of fig
      jq # json query language and formatter
      lolcat # rainbow text (welcome message)
      mise # polyglot runtime manager
      noti # xplatform notifications tool
      ripgrep
      sops # Secret operations.  Uses age keys to encrypt and decrypte files, opening them in default editor.
      ssh-to-age # utility to convert ssh keys to age keys, used by sops for secrets management in nix
      starship # cross-shell prompt
      stdenv.cc # c compiler
      # timewarrior + timew-sync-client are owned by users/brpol/home/timewarrior.nix
      tmux
      tree
      wget
      zoxide # smarter cd
      zsh
    ]
    ++ [
      neovimPkg.${pkgs.stdenv.hostPlatform.system}.default # nightly neovim
    ];

  # Cache sudo credentials for 10 minutes.
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=10
  '';

  environment.variables.EDITOR = "nvim";
  # rebuild.script is a writeShellApplication (a directory); point the alias at
  # its executable via getExe.
  environment.shellAliases.nrs = lib.getExe config.rcfiles_nix.rebuild.script;

  # zsh.enable makes zsh available as a login shell system-wide; individual
  # users opt in by setting shell = pkgs.zsh (or bashInteractive) in their nixos.nix.
  programs.zsh.enable = true;

  # pay-respects: corrects the previous command (thefuck successor). The NixOS
  # module wires the hook into the system-wide interactiveShellInit for bash/zsh/
  # fish, so every user — brpol, root, and any future account — gets it from this
  # one declaration rather than a per-user Home Manager opt-in. `f` is the alias.
  programs.pay-respects.enable = true;
}
