# Baseline configuration imported by every host via mkHost.
# Put things here if they should be true on every machine you own.
{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./common/nix-daemon.nix
    ./common/secrets.nix
  ];

  # Base CLI tools available on every host. GUI apps belong in modules/desktop.nix.
  environment.systemPackages = with pkgs; [
    _7zip-zstd # compress and uncompress
    alejandra # nix code formatter
    asciinema # terminal session recorder
    bat # cat with wings
    beamPackages.elixir
    beamPackages.erlang
    beamPackages.elixir-ls
    bitwarden-cli
    cachix # nix caching system
    chafa # image-to-terminal renderer (used by cati alias)
    claude-code # anthropic ai coding agint
    cmake
    cowsay
    csharpier # dotnet formatter
    codex # openai ai coding agent
    curl
    difftastic # structural diff tool (used by jj)
    dotnet-sdk_10 # SDK is required by Mason to install dotnet tools
    eza # modern ls replacement
    fsautocomplete # fsharp language server
    fantomas # f# formatter
    fastfetch
    fh # flakehub
    figlet # banner text generator
    fortune # random fortune cookies
    fzf
    gh # UI to a bad forge
    git
    glow # markdown rendering in the cli
    gnumake # make, need this sometimes
    go # googley c
    htop
    jj # version control of the modern times, reminds me of fig
    jq # json query language and formatter
    lolcat # rainbow text (welcome message)
    mise # polyglot runtime manager
    ncdu # disk usage analyzer
    nixd # nix lsp (not in mason for nvim)
    noti # xplatform notifications tool
    nodejs # javascript on the server
    presenterm # terminal presentations from markdown
    python3
    rclone # mount google drive or other remote stores etc
    ripgrep # grep bug rip
    rustup # rust setup
    terraform # infra as code
    timewarrior # time tracking
    tokei # code statistics
    unzip # see zip
    uv # python project management
    sops # Secret operations.  Uses age keys to encrypt and decrypte files, opening them in default editor.
    ssh-to-age # utility to convert ssh keys to age keys, used by sops for secrets management in nix
    starship # cross-shell prompt
    stdenv.cc # c compiler
    tmux
    tree
    wget
    zip # compress and decomrpess
    zoxide # smarter cd
    zsh
  ];

  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  environment.variables.EDITOR = "nvim";
  # rebuild.script is a writeShellApplication (a directory); point the alias at
  # its executable via getExe.
  environment.shellAliases.nrs = lib.getExe config.rcfiles_nix.rebuild.script;

  # zsh.enable makes zsh available as a login shell system-wide; individual
  # users opt in by setting shell = pkgs.zsh (or bashInteractive) in their
  # platform-specific user file.
  programs.zsh.enable = true;
}
