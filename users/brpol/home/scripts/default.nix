{pkgs, ...}: let
  seed-rcfiles-from-nix-store = import ./seed-rcfiles-from-nix-store.nix {inherit pkgs;};

  rcfiles = import ../../../../lib/rcfiles.nix;
  # Repository/checkout constants injected into scripts via runtimeEnv instead of
  # being read from /etc or hard-coded as string literals.
  checkoutEnv = {RCFILES_CHECKOUT_DIR = rcfiles.checkoutDir;};

  brpol-setup = pkgs.writeShellApplication {
    name = "brpol-setup";
    runtimeInputs = [
      pkgs.jujutsu
      pkgs.coreutils
      ensure-age-key
      ensure-ssh-key
      ensure-gh-auth
      ensure-gh-ssh-key
      register-ssh-key-nix
    ];
    runtimeEnv = checkoutEnv // {RCFILES_SSH_URL = rcfiles.sshUrl;};
    text = builtins.readFile ./brpol-setup.sh;
  };

  register-ssh-key-nix = pkgs.writeShellApplication {
    name = "register-ssh-key-nix";
    runtimeInputs = [pkgs.jujutsu pkgs.openssh pkgs.coreutils pkgs.diffutils ensure-ssh-key];
    runtimeEnv = checkoutEnv;
    text = builtins.readFile ./register-ssh-key-nix.sh;
  };

  ensure-ssh-key = pkgs.writeShellApplication {
    name = "ensure-ssh-key";
    runtimeInputs = [pkgs.openssh pkgs.coreutils];
    text = builtins.readFile ./ensure-ssh-key.sh;
  };

  ensure-gh-auth = pkgs.writeShellApplication {
    name = "ensure-gh-auth";
    runtimeInputs = [pkgs.gh];
    text = builtins.readFile ./ensure-gh-auth.sh;
  };

  ensure-gh-ssh-key = pkgs.writeShellApplication {
    name = "ensure-gh-ssh-key";
    runtimeInputs = [pkgs.gh pkgs.coreutils];
    text = builtins.readFile ./ensure-gh-ssh-key.sh;
  };

  ensure-age-key = pkgs.writeShellApplication {
    name = "ensure-age-key";
    runtimeInputs = [pkgs.bitwarden-cli pkgs.jq pkgs.coreutils];
    text = builtins.readFile ./ensure-age-key.sh;
  };

  edit-nix-secrets = pkgs.writeShellApplication {
    name = "edit-nix-secrets";
    runtimeInputs = [ensure-age-key pkgs.sops];
    runtimeEnv = checkoutEnv;
    text = builtins.readFile ./edit-nix-secrets.sh;
  };

  update-secret-keys = pkgs.writeShellApplication {
    name = "update-secret-keys";
    runtimeInputs = [ensure-age-key pkgs.sops pkgs.coreutils pkgs.ssh-to-age pkgs.yq-go];
    runtimeEnv = checkoutEnv;
    text = builtins.readFile ./update-secret-keys.sh;
  };
in {
  home.packages = [
    seed-rcfiles-from-nix-store
    brpol-setup
    ensure-age-key
    edit-nix-secrets
    update-secret-keys
    ensure-ssh-key
    ensure-gh-auth
    ensure-gh-ssh-key
    register-ssh-key-nix
  ];
}
