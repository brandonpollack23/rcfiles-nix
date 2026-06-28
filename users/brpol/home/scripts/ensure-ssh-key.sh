# Generate brpol's ed25519 SSH key at ~/.ssh/id_ed25519 if it does not exist.
# Idempotent; takes no arguments.
if [ "$#" -ne 0 ]; then
  echo "usage: ensure-ssh-key" >&2
  exit 2
fi

SSH_KEY="$HOME/.ssh/id_ed25519"
if [ -f "$SSH_KEY" ]; then
  echo "SSH key already exists at $SSH_KEY, skipping generation." >&2
  exit 0
fi
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
ssh-keygen -t ed25519 -C "brpol@$(uname -n)" -f "$SSH_KEY"
