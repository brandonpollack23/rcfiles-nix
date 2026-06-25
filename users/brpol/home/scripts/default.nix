{pkgs, ...}: let
  brpol-setup = pkgs.writeShellApplication {
    name = "brpol-setup";
    runtimeInputs = [ensure-age-key ensure-ssh-key ensure-gh-auth ensure-gh-ssh-key register-ssh-key-nix];
    text = builtins.readFile ./brpol-setup.sh;
  };

  register-ssh-key-nix = pkgs.writeShellApplication {
    name = "register-ssh-key-nix";
    runtimeInputs = [pkgs.git pkgs.openssh pkgs.coreutils ensure-ssh-key];
    text = builtins.readFile ./register-ssh-key-nix.sh;
  };

  ensure-ssh-key = pkgs.writeShellApplication {
    name = "ensure-ssh-key";
    runtimeInputs = [pkgs.openssh];
    text = builtins.readFile ./ensure-ssh-key.sh;
  };

  ensure-gh-auth = pkgs.writeShellApplication {
    name = "ensure-gh-auth";
    runtimeInputs = [pkgs.gh];
    text = builtins.readFile ./ensure-gh-auth.sh;
  };

  ensure-gh-ssh-key = pkgs.writeShellApplication {
    name = "ensure-gh-ssh-key";
    runtimeInputs = [pkgs.gh];
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
    text = builtins.readFile ./edit-nix-secrets.sh;
  };

  update-secret-keys = pkgs.writeShellApplication {
    name = "update-secret-keys";
    runtimeInputs = [ensure-age-key pkgs.sops pkgs.coreutils pkgs.ssh-to-age pkgs.gawk pkgs.gnugrep];
    text = builtins.readFile ./update-secret-keys.sh;
  };
in {
  home.packages = [
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
