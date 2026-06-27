{...}: {
  # Shell functions and the one dynamic alias that has to be computed at startup.
  programs.zsh.initContent = ''
    # ── Application aliases ───────────────────────────────────────────────────
    # cati must read the underlying terminal at startup, so it can't be a static
    # shellAlias.
    UNDERLYING_TERM=$(tmux display-message -p "#{client_termname}" 2>/dev/null || echo "$TERM")
    alias cati="TERM=$UNDERLYING_TERM chafa"

    # ── Custom functions ──────────────────────────────────────────────────────
    function dates() {
      echo "UTC: $(TZ=UTC date)"
      echo "JST: $(TZ=Asia/Tokyo date)"
      echo "PST: $(TZ=America/Los_Angeles date)"
      echo "EST: $(TZ=America/New_York date)"
    }

    # JJ workspace switcher using fzf.
    function jjws() {
      local selection
      selection=$(jj workspace list -T 'self.name() ++ "\t" ++ self.root() ++ "\n"' \
        | fzf --prompt="workspace> " \
              --delimiter='\t' \
              --with-nth=1 \
              --preview 'jj log -T "builtin_log_comfortable" -R {2}') \
        || return
      local dir
      dir=$(echo "$selection" | cut -f2)
      cd "$dir"
    }
  '';
}
