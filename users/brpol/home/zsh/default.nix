{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./aliases.nix
    ./functions.nix
    ./starship.nix
  ];

  home.packages = with pkgs; [
    # Completion libraries added to the user profile so their share/zsh/site-functions
    # lands in the HM-managed fpath (picked up at mkOrder 530 even without compinit).
    zsh-completions
    nix-zsh-completions
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    ALTERNATE_EDITOR = "vi";
    LESS = "-R -I";
    ERL_AFLAGS = "-kernel shell_history enabled";
    PROJECT_DIRS = "$HOME/src";
  };

  # zoxide/fzf/mise integrations are managed by their native HM modules below
  # instead of hand-wired `eval`/`source` lines, so home-manager controls their
  # ordering in the generated zshrc.
  programs.zoxide = {
    enable = true;
    options = ["--cmd" "cd"];
  };

  programs.fzf = {
    enable = true;
    defaultOptions = ["--bind" "ctrl-f:page-down,ctrl-b:page-up"];
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    history = {
      size = 50000;
      save = 50000;
      share = true;
    };

    # Oh-My-Zsh supplies the maintained git/systemd aliases.
    oh-my-zsh = {
      enable = true;
      # git/systemd: maintained command aliases. jj: jj* aliases + manages jj
      # shell completion (replaces a manual COMPLETE=zsh jj source).
      # common-aliases: global pipe aliases (G/H/L/T/NUL/...) plus interactive
      # rm/cp/mv -i and assorted ls helpers.
      plugins = ["git" "systemd" "jj" "common-aliases"];
      # The nix store is read-only; silence OMZ's self-update check.
      extraConfig = "zstyle ':omz:update' mode disabled";
    };

    plugins = [
      # fzf-tab must load after compinit but before syntax-highlighting/autosuggestions.
      # Replaces the default zsh completion menu with fzf.
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "zsh-you-should-use";
        src = pkgs.zsh-you-should-use;
        file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
      }
    ];

    initContent = lib.mkMerge [
      # General configuration (mkOrder 1000, replaces the old initExtra).
      ''
        # ── Completion cache ──────────────────────────────────────────────────
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path ~/.zsh/cache

        # ── Vi mode ───────────────────────────────────────────────────────────
        bindkey -v
        bindkey -M viins 'jk' vi-cmd-mode

        # History substring search keybindings (plugin loads at mkOrder 1200).
        bindkey '^p' history-substring-search-up
        bindkey '^n' history-substring-search-down
        bindkey -M vicmd 'k' history-substring-search-up
        bindkey -M vicmd 'j' history-substring-search-down

        # zoxide/fzf/mise are wired by their native HM modules; jj completion is
        # managed by OMZ's jj plugin.

        # ── Welcome message ───────────────────────────────────────────────────
        if command -v lolcat >/dev/null 2>&1; then
          echo "Welcome to $HOST!" | lolcat
        else
          echo "Welcome to $HOST!"
        fi

        # ── Machine-local overrides (not tracked in this repo) ───────────────
        [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
      ''
    ];
  };
}
