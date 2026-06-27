{config, ...}: {
  sops.secrets."brpol/git-email" = {};
  sops.templates."git-identity.gitconfig" = {
    content = ''
      [user]
          email = ${config.sops.placeholder."brpol/git-email"}
    '';
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
    };
  };

  programs.git = {
    enable = true;

    # Email is kept out of the nix store — it comes from the sops-rendered template.
    # Run edit-nix-secrets to add git-email to secrets/secrets.yaml before first activation.
    includes = [
      {path = config.sops.templates."git-identity.gitconfig".path;}
      # Machine-specific git config lives in
      # hosts/<hostname>/home-overrides/brpol/git.nix and is merged in by mkHost.
    ];

    lfs.enable = true;

    settings = {
      user.name = "Brandon Pollack";

      core.editor = "nvim";
      pull.rebase = true;
      init.defaultBranch = "master";
      submodule.recurse = true;
      color.ui = "auto";
      diff.colorMoved = "default";
      fetch.prune = false;

      merge.tool = "nvimdiffview";
      "mergetool \"nvimdiffview\"" = {
        cmd = "nvim -c 'DiffviewOpen'";
        trustExitCode = true;
      };

      "filter \"lfs\"" = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };
  };
}
