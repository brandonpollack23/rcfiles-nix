_flake_path=$(cat /etc/rcfiles-nix/flake-path 2>/dev/null || echo "$HOME/rcfiles-nix")
_pub_src="$HOME/.ssh/id_ed25519.pub"
_pub_dst="$_flake_path/hosts/$(hostname)/user.pub"

if [[ ! -f "$_pub_src" ]]; then
  ensure-ssh-key
fi

mkdir -p "$(dirname "$_pub_dst")"

if [[ -f "$_pub_dst" ]] && diff -q "$_pub_src" "$_pub_dst" >/dev/null 2>&1; then
  echo "Key already registered for $(hostname), nothing to do." >&2
  exit 0
fi

cp "$_pub_src" "$_pub_dst"
git -C "$_flake_path" add "hosts/$(hostname)/user.pub"

if git -C "$_flake_path" diff --cached --quiet; then
  echo "Key already staged/committed for $(hostname), nothing to do." >&2
else
  git -C "$_flake_path" commit -m "feat: register SSH public key for $(hostname)"
  git -C "$_flake_path" pull --rebase
  git -C "$_flake_path" push
fi

unset _flake_path _pub_src _pub_dst
