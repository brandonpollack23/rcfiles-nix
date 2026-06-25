{sopsNixModule, ...}: {
  imports = [sopsNixModule];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.secrets.cachix-brandonpollack23 = {};

  # Warns if the sops primary key (for editing and setup of this machine's key) is not set up yet.
  environment.interactiveShellInit = ''
    if [ "$(id -un)" = "brpol" ] && [ ! -f "$HOME/.config/sops/age/keys.txt" ]; then
      printf '\033[1;33m\nWARNING: personal age key not found.\033[0m\n'
      printf 'Run \033[1mensure-age-key\033[0m to fetch from Bitwarden,\n'
      printf 'or \033[1medit-nix-secrets\033[0m / \033[1mupdate-secret-keys\033[0m will do it on demand.\n\n'
    fi
  '';
}
