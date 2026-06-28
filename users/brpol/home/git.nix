{
  config,
  lib,
  ...
}: {
  sops.secrets."brpol/git-email" = {};
  sops.templates."git-identity.gitconfig" = {
    # Serialize with toGitINI rather than hand-formatting the INI text.
    content = lib.generators.toGitINI {
      user.email = config.sops.placeholder."brpol/git-email";
    };
    # Render to an explicit final path under ~/.config/git, included below.
    path = "${config.xdg.configHome}/git/git-identity.gitconfig";
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
      fetch.prune = true;

      merge.tool = "nvimdiffview";
      "mergetool \"nvimdiffview\"" = {
        cmd = "nvim -c 'DiffviewOpen'";
        # Diffview can't reliably signal merge success via exit code, so don't
        # trust it — git prompts to confirm the merge was resolved instead.
        trustExitCode = false;
      };
    };
  };
}
