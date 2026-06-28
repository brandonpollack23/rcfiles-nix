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

    # Vi mode is owned by the zsh-vi-mode plugin (jeffreytse/zsh-vi-mode),
    # configured in the plugins list + initContent below. It supersedes
    # programs.zsh.defaultKeymap, which only emits an early `bindkey -v` that the
    # oh-my-zsh/plugin chain clobbered back to emacs.

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
      # Listed last (sourced at mkOrder 900) so ZVM initializes after oh-my-zsh's
      # `bindkey -e` (mkOrder 800) and before starship's hooks (mkOrder 1000).
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
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
        # render fzf in a tmux popup (autoloaded from fzf-tab's lib; needs tmux 3.2+,
        # falls back to plain fzf outside tmux)
        zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
        # popup sizing: never smaller than 50x8; leave horizontal padding so the
        # popup floats rather than filling the pane
        zstyle ':fzf-tab:*' popup-min-size 50 8
        zstyle ':fzf-tab:*' popup-pad 30 0

        # ── History number for the prompt ─────────────────────────────────────
        # Starship can't read zsh's special $HISTCMD directly, so copy it into a
        # plain env var each prompt for starship's env_var module to display.
        autoload -Uz add-zsh-hook
        _starship_export_histcmd() { export STARSHIP_HISTCMD=$HISTCMD; }
        add-zsh-hook precmd _starship_export_histcmd

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

      # ── Vi mode (zsh-vi-mode) ─────────────────────────────────────────────────
      # ZVM config must be set before the plugin is sourced (plugins list, mkOrder
      # 900); this block is mkBefore (mkOrder 500). The plugin itself is loaded
      # from the plugins list above — see that entry for the ordering rationale.
      (lib.mkBefore ''
        ZVM_INIT_MODE=sourcing
        # jk leaves insert mode instead of the default Esc.
        ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
        # Seconds to wait for the rest of a multi-key sequence like jk.
        ZVM_KEYTIMEOUT=0.2

        # ZVM resets the keymaps on init, dropping bindings from fzf, fzf-tab and
        # history-substring-search and stripping readline editing keys from insert
        # mode. Re-apply them in this hook, which ZVM runs once init completes.
        # (bindkey may name a widget defined by a later-sourced plugin; zsh
        # resolves the widget at keypress time, so the ordering is fine.)
        function zvm_after_init() {
          # Keep common readline editing keys usable in vi insert mode.
          bindkey -M viins '^A' beginning-of-line
          bindkey -M viins '^E' end-of-line
          bindkey -M viins '^U' backward-kill-line
          bindkey -M viins '^K' kill-line
          bindkey -M viins '^W' backward-kill-word
          bindkey -M viins '^Y' yank

          # History substring search: ^p/^n in insert, j/k in command mode.
          bindkey -M viins '^P' history-substring-search-up
          bindkey -M viins '^N' history-substring-search-down
          bindkey -M vicmd 'k' history-substring-search-up
          bindkey -M vicmd 'j' history-substring-search-down

          # fzf widgets and fzf-tab completion.
          bindkey -M viins '^R' fzf-history-widget
          bindkey -M viins '^T' fzf-file-widget
          bindkey -M viins '^I' fzf-tab-complete
        }
      '')
    ];
  };
}
