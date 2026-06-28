# Upload brpol's SSH public key to GitHub as an authentication key. Idempotent
# (GitHub rejects duplicates, which is treated as success); takes no arguments.
if [ "$#" -ne 0 ]; then
  echo "usage: ensure-gh-ssh-key" >&2
  exit 2
fi

SSH_KEY="$HOME/.ssh/id_ed25519"
if gh ssh-key add "$SSH_KEY.pub" \
  --title "brpol@$(uname -n)" \
  --type authentication 2>/dev/null; then
  echo "SSH public key added to GitHub." >&2
else
  echo "SSH key may already be registered with GitHub (skipping)." >&2
fi
