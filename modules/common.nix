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
    ./common/nix-ld.nix
    ./common/secrets.nix
    ./common/i18n.nix
    ./common/ssh.nix
  ];

  # Base CLI tools available on every host. GUI apps belong in modules/desktop.nix.
  environment.systemPackages = with pkgs; [
    _7zip-zstd # compress and uncompress
    alejandra # nix code formatter
    bat # cat with wings
    beamPackages.elixir
    beamPackages.erlang
    beamPackages.elixir-ls
    bitwarden-cli
    cachix # nix caching system
    chafa # image-to-terminal renderer (used by cati alias)
    claude-code # anthropic ai coding agint
    cmake
    csharpier # dotnet formatter
    codex # openai ai coding agent
    curl
    difftastic # structural diff tool (used by jj)
    dotnet-runtime_10 # java but microsofty
    eza # modern ls replacement
    fsautocomplete # fsharp language server
    fantomas # f# formatter
    fastfetch
    fh # flakehub
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
    nixd # nix lsp (not in mason for nvim)
    noti # xplatform notifications tool
    nodejs # javascript on the server
    python3
    rclone # mount google drive or other remote stores etc
    ripgrep # grep bug rip
    rustup # rust setup
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
