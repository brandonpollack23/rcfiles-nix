{
  lib,
  pkgs,
  ...
}: let
  # Package-qualified executables so the prompt doesn't depend on PATH.
  git = lib.getExe pkgs.git;
  jj = lib.getExe' pkgs.jujutsu "jj";
  date = lib.getExe' pkgs.coreutils "date";
  awk = lib.getExe' pkgs.gawk "awk";
  starship-jj = lib.getExe pkgs.starship-jj;

  tomlFormat = pkgs.formats.toml {};
in {
  home.packages = [pkgs.starship-jj];

  # ── Starship prompt ───────────────────────────────────────────────────────
  programs.starship = {
    enable = true;
    settings = {
      # user@host  [hh:MM:SS AM (TZ) | hh:MM:SS AM (UTC)]  cwd  vcs
      # ❯
      format = lib.concatStrings [
        ''$username@$hostname ''
        ''\[$time | ''${custom.utc_time}\] ''
        ''\[$directory\]$status ''
        ''''${custom.git_branch}''
        ''''${custom.git_status}''
        ''''${custom.jj}''
        ''$line_break''
        ''$character''
      ];

      username = {
        show_always = true;
        format = "[$user]($style)";
        style_user = "bold green";
        style_root = "bold red";
      };

      hostname = {
        disabled = false;
        ssh_only = false;
        format = "[$hostname]($style)";
        style = "bold green";
      };

      time = {
        disabled = false;
        format = "[$time]($style)";
        time_format = "%I:%M:%S %p %z(%Z)";
        style = "bold blue";
      };

      custom.utc_time = {
        description = "Current UTC time";
        command = "${date} -u '+%H:%M:%S (UTC)'";
        when = true;
        format = "[$output]($style)";
        style = "bold blue";
        shell = ["sh" "-c"];
        use_stdin = false;
      };

      directory = {
        format = "[$path]($style)[$read_only]($read_only_style)";
        truncation_length = 5;
        truncate_to_repo = false;
        style = "bold white";
      };

      # Built-in git modules disabled; custom versions below only fire outside jj repos.
      git_branch.disabled = true;
      git_status.disabled = true;

      custom.git_branch = {
        when = "${git} rev-parse --is-inside-work-tree 2>/dev/null && ! ${jj} root --ignore-working-copy 2>/dev/null";
        command = "${git} branch --show-current 2>/dev/null";
        format = "[ $output]($style) ";
        style = "bold purple";
        shell = ["sh" "-c"];
        use_stdin = false;
      };

      custom.git_status = {
        when = "${git} rev-parse --is-inside-work-tree 2>/dev/null && ! ${jj} root --ignore-working-copy 2>/dev/null";
        command = ''
          ${git} status --porcelain 2>/dev/null | ${awk} '
            /^\?\? /     { u=1 }
            /^[MADRC]  / { s=1 }
            /^.[MADRC]/  { m=1 }
            END { if (s) printf "+"; if (m) printf "!"; if (u) printf "?" }
          '
        '';
        format = "([$output]($style)) ";
        style = "bold red";
        shell = ["sh" "-c"];
        use_stdin = false;
      };

      custom.jj = {
        description = "jj repo info via starship-jj";
        when = true;
        command = "prompt";
        format = "$output";
        ignore_timeout = true;
        shell = [starship-jj "--ignore-working-copy" "starship"];
        use_stdin = false;
      };

      status = {
        # Success symbol is nothing (module renders empty on a zero exit);
        # only a non-zero exit shows the angry-face error symbol.
        disabled = false;
        format = "[ $symbol]($style)";
        symbol = "😠";
        style = "bold red";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold yellow)";
        vimcmd_replace_one_symbol = "[❮](bold purple)";
        vimcmd_replace_symbol = "[❮](bold purple)";
        vimcmd_visual_symbol = "[❮](bold cyan)";
      };
    };
  };

  xdg.configFile."starship-jj/starship-jj.toml".source = tomlFormat.generate "starship-jj.toml" {
    module_separator = " ";
    reset_color = false;

    bookmarks = {
      search_depth = 100;
      exclude = [];
    };

    module = [
      {
        type = "Symbol";
        symbol = "󱗆 ";
        color = "Blue";
      }
      {
        type = "Bookmarks";
        separator = " ";
        color = "Magenta";
        behind_symbol = "⇡";
        surround_with_quotes = false;
        ignore_empty_commits = "None";
      }
    ];
  };
}
