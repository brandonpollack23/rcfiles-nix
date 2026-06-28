{
  pkgs,
  tmuxExtraPlugins,
  ...
}: let
  tmuxMenusPkg = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-menus";
    version = tmuxExtraPlugins.tmux-menus.shortRev or "unknown";
    rtpFilePath = "menus.tmux";
    src = tmuxExtraPlugins.tmux-menus;
  };

  tmuxEasyMotionPkg = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-easy-motion";
    version = tmuxExtraPlugins.tmux-easy-motion.shortRev or "unknown";
    rtpFilePath = "easy_motion.tmux";
    src = tmuxExtraPlugins.tmux-easy-motion;
  };
in {
  programs.tmux = {
    enable = true;

    prefix = "C-a";
    keyMode = "vi";
    historyLimit = 50000;
    escapeTime = 0;
    baseIndex = 1;
    terminal = "tmux-256color";
    aggressiveResize = true;
    sensibleOnTop = false;
    mouse = true;
    focusEvents = true;

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-capture-pane-contents 'on'";
      }
      {
        plugin = continuum;
        extraConfig = "set -g @continuum-restore 'on'";
      }
      yank
      {
        plugin = fingers;
        extraConfig = "bind F run -b \"#{@fingers-cli} start #{pane_id}\"";
      }
      tmuxMenusPkg
      {
        plugin = tmuxEasyMotionPkg;
        extraConfig = "set -g @easy-motion-prefix \"Space\"";
      }
      {
        plugin = dracula;
        extraConfig = ''
          set -g @dracula-show-powerline true
          set -g @dracula-plugins "cpu-usage ram-usage gpu-usage time"
          set -g @dracula-show-flags true
          set -g @dracula-show-left-icon "#h | #S"
          set -g @dracula-show-timezone false
          set -g @dracula-military-time true
          set -g status-position bottom
        '';
      }
    ];

    extraConfig = ''
      # ── Terminal passthrough ───────────────────────────────────────────────
      set -g allow-passthrough on
      # Import TERM_PROGRAM from the client, but never TERM — tmux owns its
      # internal TERM (tmux-256color); overwriting it breaks terminfo inside.
      set -ga update-environment TERM_PROGRAM
      # Modern truecolor advertisement via terminal-features (FAQ-recommended).
      set -as terminal-features ",xterm-256color:RGB"

      # ── Window/pane settings ───────────────────────────────────────────────
      set-option -g allow-rename off
      set-option -g renumber-windows on
      set -g display-time 4000
      set -g status-interval 5
      set -g status-keys emacs

      # ── Custom prefix ──────────────────────────────────────────────────────
      bind C-a send-prefix

      # ── Split bindings ─────────────────────────────────────────────────────
      unbind '"'
      unbind %
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # ── Vim pane navigation ────────────────────────────────────────────────
      bind h select-pane -L
      bind -n C-S-h select-pane -L
      bind j select-pane -D
      bind -n C-S-j select-pane -D
      bind k select-pane -U
      bind -n C-S-k select-pane -U
      bind l select-pane -R
      bind -n C-S-l select-pane -R

      # ── Window navigation ──────────────────────────────────────────────────
      bind -n C-M-] next-window
      bind -n C-M-[ previous-window
      bind-key -n 'C-M-{' swap-window -t -1 \; select-window -t -1
      bind-key -n 'C-M-}' swap-window -t +1 \; select-window -t +1
      bind-key C-w choose-window "swap-window -t '%%'"
      bind -n C-M-t new-window

      # ── Pane resizing ──────────────────────────────────────────────────────
      # Uppercase H/J/K/L, repeatable (-r). C-h/C-l are reserved for window
      # reordering below, so resizing can't use them without clobbering.
      bind = select-layout -E
      bind -r H resize-pane -L 3
      bind -r J resize-pane -D 3
      bind -r K resize-pane -U 3
      bind -r L resize-pane -R 3

      # ── Window reordering ──────────────────────────────────────────────────
      bind-key -r C-h swap-window -t -1\; select-window -t -1
      bind-key -r C-l swap-window -t +1\; select-window -t +1

      # ── Halfpage scroll ────────────────────────────────────────────────────
      bind -n C-S-u copy-mode -e \; send-keys -X halfpage-up
      bind -n C-S-d copy-mode -e \; send-keys -X halfpage-down

      # ── Copy mode (vi) ─────────────────────────────────────────────────────
      bind-key v next-layout
      bind-key -T copy-mode-vi v send-keys -X begin-selection
    '';
  };
}
