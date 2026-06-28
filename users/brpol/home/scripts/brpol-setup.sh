# One-time per-user bootstrap for brpol: fetch the age key, create and upload an
# SSH key, authenticate gh, switch the rcfiles remote to SSH, and register this
# host's key in the flake. Idempotent; takes no arguments. Repo location and SSH
# remote are injected via RCFILES_CHECKOUT_DIR / RCFILES_SSH_URL.
if [ "$#" -ne 0 ]; then
  echo "usage: brpol-setup" >&2
  exit 2
fi

echo "=== brpol one-time setup ===" >&2

echo "" >&2
echo "--- Step 1: age key ---" >&2
ensure-age-key

echo "" >&2
echo "--- Step 2: SSH key ---" >&2
ensure-ssh-key

echo "" >&2
echo "--- Step 3: GitHub auth ---" >&2
ensure-gh-auth

echo "" >&2
echo "--- Step 4: upload SSH public key to GitHub ---" >&2
ensure-gh-ssh-key

echo "" >&2
echo "--- Step 5: switch rcfiles-nix remote to SSH ---" >&2
_flake_path="$HOME/$RCFILES_CHECKOUT_DIR"
git -C "$_flake_path" remote set-url origin "$RCFILES_SSH_URL"
unset _flake_path

echo "" >&2
echo "--- Step 6: register this host's SSH public key in the flake ---" >&2
register-ssh-key-nix

echo "" >&2
echo "=== Setup complete! ===" >&2
