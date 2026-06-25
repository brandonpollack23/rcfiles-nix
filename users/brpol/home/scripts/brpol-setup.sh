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
_flake_path=$(cat /etc/rcfiles-nix/flake-path 2>/dev/null || echo "$HOME/rcfiles-nix")
git -C "$_flake_path" remote set-url origin git@github.com:brandonpollack23/rcfiles-nix.git
unset _flake_path

echo "" >&2
echo "--- Step 6: register this host's SSH public key in the flake ---" >&2
register-ssh-key-nix

echo "" >&2
echo "=== Setup complete! ===" >&2
