SOPS_YAML="$HOME/rcfiles-nix/.sops.yaml"
ensure-age-key

HOST_AGE_KEY=$(sudo cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age)

if ! grep -qF "$HOST_AGE_KEY" "$SOPS_YAML"; then
  awk -v key="          - $HOST_AGE_KEY # $(hostname)" '
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

exec sops --config "$HOME/rcfiles-nix/.sops.yaml" updatekeys "$HOME/rcfiles-nix/secrets/secrets.yaml"
