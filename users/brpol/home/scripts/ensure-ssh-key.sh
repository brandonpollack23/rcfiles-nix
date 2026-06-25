SSH_KEY="$HOME/.ssh/id_ed25519"
if [ -f "$SSH_KEY" ]; then
  echo "SSH key already exists at $SSH_KEY, skipping generation." >&2
  exit 0
fi
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
ssh-keygen -t ed25519 -C "brpol@$(hostname)" -f "$SSH_KEY"
