# Home-manager config for brpol.
# This directory is the entry point; split into sub-files and import them here
# as the config grows (e.g. ./shell.nix, ./git.nix, ./neovim.nix).
{
  config,
  pkgs,
  stateVersion,
  ...
}: let
  # One-time machine setup: age key, SSH key pair, GitHub auth. Idempotent — each step skips if already done.
  brpol-setup = pkgs.writeShellScriptBin "brpol-setup" ''
    set -euo pipefail

    echo "=== brpol one-time setup ===" >&2

    echo "" >&2
    echo "--- Step 1: age key ---" >&2
    ${ensure-age-key}/bin/ensure-age-key

    echo "" >&2
    echo "--- Step 2: SSH key ---" >&2
    ${ensure-ssh-key}/bin/ensure-ssh-key

    echo "" >&2
    echo "--- Step 3: GitHub auth ---" >&2
    ${ensure-gh-auth}/bin/ensure-gh-auth

    echo "" >&2
    echo "--- Step 4: upload SSH public key to GitHub ---" >&2
    ${ensure-gh-ssh-key}/bin/ensure-gh-ssh-key

    echo "" >&2
    echo "=== Setup complete! ===" >&2
  '';

  # Generates ~/.ssh/id_ed25519 if absent; prompts for passphrase interactively.
  ensure-ssh-key = pkgs.writeShellScriptBin "ensure-ssh-key" ''
    set -euo pipefail
    SSH_KEY="$HOME/.ssh/id_ed25519"
    if [ -f "$SSH_KEY" ]; then
      echo "SSH key already exists at $SSH_KEY, skipping generation." >&2
      exit 0
    fi
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -C "brpol@$(hostname)" -f "$SSH_KEY"
  '';

  # Authenticates the GitHub CLI with SSH protocol via browser OAuth if not already logged in.
  ensure-gh-auth = pkgs.writeShellScriptBin "ensure-gh-auth" ''
    set -euo pipefail
    if ${pkgs.gh}/bin/gh auth status --hostname github.com >/dev/null 2>&1; then
      echo "Already authenticated with github.com, skipping login." >&2
      exit 0
    fi
    ${pkgs.gh}/bin/gh auth login \
      --hostname github.com \
      --git-protocol ssh \
      --web
  '';

  # Uploads ~/.ssh/id_ed25519.pub to the authenticated GitHub account; skips if already registered.
  ensure-gh-ssh-key = pkgs.writeShellScriptBin "ensure-gh-ssh-key" ''
    set -euo pipefail
    SSH_KEY="$HOME/.ssh/id_ed25519"
    if ${pkgs.gh}/bin/gh ssh-key add "$SSH_KEY.pub" \
      --title "brpol@$(hostname)" \
      --type authentication 2>/dev/null; then
      echo "SSH public key added to GitHub." >&2
    else
      echo "SSH key may already be registered with GitHub (skipping)." >&2
    fi
  '';

  # Checks for ~/.config/sops/age/keys.txt and, if absent, fetches the raw
  # AGE-SECRET-KEY-1... value from a Bitwarden secure note named "age-private-key",
  # writes it to the key file, and sets permissions. Exits non-zero on any failure.
  # Run this standalone before any raw `sops` call on a fresh machine.
  ensure-age-key = pkgs.writeShellScriptBin "ensure-age-key" ''
    set -euo pipefail
    KEYS_FILE="$HOME/.config/sops/age/keys.txt"
    if [ -f "$KEYS_FILE" ]; then
      echo "Key file ~/.config/sops/age/keys.txt already exists, if you'd like to regenerate please remove it first"
      exit 0
    fi
    echo "Age key not found at $KEYS_FILE — fetching from Bitwarden..." >&2
    _bw_opened=false
    STATUS=$(${pkgs.bitwarden-cli}/bin/bw status | ${pkgs.jq}/bin/jq -r '.status')
    case "$STATUS" in
      unauthenticated)
        export BW_SESSION
        BW_SESSION=$(${pkgs.bitwarden-cli}/bin/bw login --raw)
        _bw_opened=true
        ;;
      locked)
        export BW_SESSION
        BW_SESSION=$(${pkgs.bitwarden-cli}/bin/bw unlock --raw)
        _bw_opened=true
        ;;
    esac
    # Lock on exit only if we were the ones who opened the vault.
    trap '[ "$_bw_opened" = true ] && ${pkgs.bitwarden-cli}/bin/bw lock >/dev/null' EXIT
    KEY=$(${pkgs.bitwarden-cli}/bin/bw get notes "age-private-key")
    if [ -z "$KEY" ]; then
      echo "error: Bitwarden note 'age-private-key' is empty or not found" >&2
      exit 1
    fi
    mkdir -p "$(dirname "$KEYS_FILE")"
    printf '%s\n' "$KEY" > "$KEYS_FILE"
    chmod 600 "$KEYS_FILE"
    echo "Age key saved to $KEYS_FILE" >&2
  '';

  # Opens secrets/secrets.yaml in $EDITOR via sops, bootstrapping the personal
  # age key from Bitwarden first if ~/.config/sops/age/keys.txt is absent.
  edit-nix-secrets = pkgs.writeShellScriptBin "edit-nix-secrets" ''
    set -euo pipefail
    ${ensure-age-key}/bin/ensure-age-key
    exec ${pkgs.sops}/bin/sops "$HOME/rcfiles-nix/secrets/secrets.yaml"
  '';

  # Registers this machine in .sops.yaml (if not already present) then re-encrypts
  # secrets/secrets.yaml for all recipients. Safe to run on existing machines —
  # skips the registration step if the host key is already listed.
  update-secret-keys = pkgs.writeShellScriptBin "update-secret-keys" ''
    set -euo pipefail
    SOPS_YAML="$HOME/rcfiles-nix/.sops.yaml"
    ${ensure-age-key}/bin/ensure-age-key

    HOST_AGE_KEY=$(sudo ${pkgs.coreutils}/bin/cat /etc/ssh/ssh_host_ed25519_key.pub | ${pkgs.ssh-to-age}/bin/ssh-to-age)

    if ! grep -qF "$HOST_AGE_KEY" "$SOPS_YAML"; then
      ${pkgs.gawk}/bin/awk -v key="          - $HOST_AGE_KEY # $(hostname)" '
        { lines[NR] = $0 }
        /^          - age1/ { last_age = NR }
        END {
          for (i = 1; i <= NR; i++) {
            print lines[i]
            if (i == last_age) print key
          }
        }
      ' "$SOPS_YAML" > "$SOPS_YAML.tmp" && mv "$SOPS_YAML.tmp" "$SOPS_YAML"
    fi

    exec ${pkgs.sops}/bin/sops --config "$HOME/rcfiles-nix/.sops.yaml" updatekeys "$HOME/rcfiles-nix/secrets/secrets.yaml"
  '';
in {
  home.username = "brpol";
  home.homeDirectory = "/home/brpol";

  # Passed in from mkHost via home-manager.extraSpecialArgs — single source of truth.
  home.stateVersion = stateVersion;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = [
    ensure-age-key
    edit-nix-secrets
    update-secret-keys
    ensure-ssh-key
    ensure-gh-auth
    ensure-gh-ssh-key
    brpol-setup
  ];

  # Desktop notification at graphical login if age key is absent.
  # XDG autostart is used instead of a systemd user service because Cinnamon+LightDM
  # does not reliably activate graphical-session.target for systemd user services.
  xdg.configFile."autostart/age-key-missing-notify.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Age Key Missing Notify
    Exec=${pkgs.writeShellScript "age-key-missing-notify" ''
      [ -f "$HOME/.config/sops/age/keys.txt" ] && exit 0
      ${pkgs.noti}/bin/noti -t "Age Key Missing" \
        -m "Run ensure-age-key to fetch from Bitwarden"
    ''}
    Hidden=false
    X-GNOME-Autostart-enabled=true
  '';

  # Lets home-manager manage itself; required when using the NixOS module.
  programs.home-manager.enable = true;
}
