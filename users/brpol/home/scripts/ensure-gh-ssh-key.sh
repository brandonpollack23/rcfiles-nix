SSH_KEY="$HOME/.ssh/id_ed25519"
if gh ssh-key add "$SSH_KEY.pub" \
  --title "brpol@$(hostname)" \
  --type authentication 2>/dev/null; then
  echo "SSH public key added to GitHub." >&2
else
  echo "SSH key may already be registered with GitHub (skipping)." >&2
fi
