{
  lib,
  pkgs,
  ...
}: {
  programs.zsh = {
    # Global aliases (alias -g). HM emits these at mkOrder 1100, after OMZ (800),
    # so these override common-aliases' defaults. H/T/NUL come from OMZ's
    # common-aliases plugin unchanged; only these rg/bat variants are overridden.
    shellGlobalAliases = {
      G = "| rg"; # common-aliases uses grep
      L = "| bat"; # common-aliases uses less
      LL = "2>&1 | bat"; # common-aliases uses less
    };

    shellAliases = {
      # eza replaces ls / tree (overrides common-aliases' ll/la `ls` variants).
      ls = "eza --group-directories-first --git";
      ll = "eza -l --group-directories-first --git";
      la = "eza -la --group-directories-first --git";
      tree = "eza -T --group-directories-first --git";

      # Convenience
      ":q" = "exit";
      # Render markdown in a pager
      mdless = "${lib.getExe pkgs.glow} -p";

      # ── Oh-My-Zsh alias overrides ───────────────────────────────────────────
      # The git/systemd/jj aliases now come from OMZ's git/systemd/jj plugins.
      # These few deliberately differ from (or are absent in) OMZ; shellAliases
      # load at mkOrder 1100, after OMZ (800), so they win.
      gfp = "git fetch --prune"; # OMZ has no `gfp`
      grbi = "git rebase -i --update-refs --autosquash"; # richer than OMZ's plain --interactive
      grss = "git restore --staged"; # OMZ's `grss` means --source

      # journalctl shorthands — OMZ's systemd plugin defines none of these.
      jc = "journalctl";
      jcu = "journalctl -u";
      jcf = "journalctl -f";
      jce = "journalctl -xe";
    };
  };
}
