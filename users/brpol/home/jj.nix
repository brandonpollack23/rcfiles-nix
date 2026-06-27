{
  lib,
  config,
  ...
}: {
  sops.templates."jj-identity.toml" = {
    content = ''
      [user]
      email = "${config.sops.placeholder."brpol/git-email"}"
    '';
  };

  # the config dir jj/conf.d is auto merged with the top level config, use it for our secrets
  home.activation.jj-email-link = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.xdg.configHome}/jj/conf.d"
    ln -sf "${config.sops.templates."jj-identity.toml".path}" \
      "${config.xdg.configHome}/jj/conf.d/identity.toml"
  '';

  programs.jujutsu = {
    enable = true;

    settings = {
      user.name = "Brandon Pollack";
      # Email comes from the sops-rendered conf.d fragment via home.activation.jj-email-link.

      ui = {
        merge-editor = "diffconflicts";
        diff-formatter = ["difft" "--color=always" "$left" "$right"];
      };

      merge-tools = {
        diffconflicts = {
          program = "nvim";
          merge-args = [
            "-c"
            "let g:jj_diffconflicts_marker_length=$marker_length"
            "-c"
            "JJDiffConflicts!"
            "$output"
            "$base"
            "$left"
            "$right"
          ];
          merge-tool-edits-conflict-markers = true;
        };

        nvim-3col = {
          program = "nvim";
          # Opens 3 vertical splits ($output center, $left and $right on the sides).
          merge-args = ["-d" "$left" "$output" "$right"];
        };

        nvim-gitstyle = {
          program = "nvim";
          # Opens all 4 files in diff mode, moves $output to bottom full-width.
          merge-args = [
            "-f"
            "-d"
            "$output"
            "$left"
            "$base"
            "$right"
            "-c"
            "wincmd J"
          ];
        };
      };

      aliases.mr = ["util" "exec" "--" "jj-vine"];
    };
  };
}
