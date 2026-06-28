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
    # Completion library added to the user profile so its share/zsh/site-functions
    # lands in the HM-managed fpath (picked up at mkOrder 530 even without compinit).
    zsh-completions
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

    defaultKeymap = "viins";

    historySubstringSearch = {
      enable = true;
      # ^p / ^n bound by the module; vi-cmd k/j are added in initContent below.
      searchUpKey = ["^p"];
      searchDownKey = ["^n"];
    };

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
        # ── fzf-tab ───────────────────────────────────────────────────────────
        # disable sort when completing `git checkout`
        zstyle ':completion:*:git-checkout:*' sort false
        # set descriptions format to enable group support
        # NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
        zstyle ':completion:*:descriptions' format '[%d]'
        # set list-colors to enable filename colorizing
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
        zstyle ':completion:*' menu no
        # preview directory's content with eza when completing cd
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
        # custom fzf flags; fzf-tab does not follow FZF_DEFAULT_OPTS by default
        # header-first pins the hint above the prompt; ^space is fzf's default toggle (multi-select)
        zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept --header='^space:toggle <>:group ^f/^b:page /:continuous-sel' --header-first
        # make fzf-tab follow FZF_DEFAULT_OPTS
        # NOTE: may cause unexpected behavior since some flags break this plugin (see Aloxaf/fzf-tab#455)
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        # switch group using `<` and `>`
        zstyle ':fzf-tab:*' switch-group '<' '>'
        # use tmux popup for fzf
        zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

        # ── Vi mode ───────────────────────────────────────────────────────────
        # Base keymap is set via programs.zsh.defaultKeymap = "viins".
        bindkey -M viins 'jk' vi-cmd-mode

        # ^p/^n are bound by historySubstringSearch.search{Up,Down}Key; add the
        # vi-cmd k/j bindings the option can't express.
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

        # Machine-specific shell config belongs in a host override under
        # hosts/<host>/home-overrides/brpol/, not an untracked ~/.zshrc.local.
      ''
    ];
  };
}
