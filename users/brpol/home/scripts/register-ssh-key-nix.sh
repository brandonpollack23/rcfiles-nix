# Register this host's SSH public key into the flake as hosts/<host>/user.pub,
# commit, and push. Generates the key first if missing. Idempotent; no arguments.
# Repo location is injected via RCFILES_CHECKOUT_DIR.
if [ "$#" -ne 0 ]; then
  echo "usage: register-ssh-key-nix" >&2
  exit 2
fi

_flake_path="$HOME/$RCFILES_CHECKOUT_DIR"
_host="$(uname -n)"
_pub_src="$HOME/.ssh/id_ed25519.pub"
_pub_dst="$_flake_path/hosts/$_host/user.pub"

if [[ ! -f "$_pub_src" ]]; then
  ensure-ssh-key
fi

mkdir -p "$(dirname "$_pub_dst")"

if [[ -f "$_pub_dst" ]] && diff -q "$_pub_src" "$_pub_dst" >/dev/null 2>&1; then
  echo "Key already registered for $_host, nothing to do." >&2
  exit 0
fi

cp "$_pub_src" "$_pub_dst"
git -C "$_flake_path" add "hosts/$_host/user.pub"

if git -C "$_flake_path" diff --cached --quiet; then
  echo "Key already staged/committed for $_host, nothing to do." >&2
else
  git -C "$_flake_path" commit -m "feat: register SSH public key for $_host"
  git -C "$_flake_path" pull --rebase
  git -C "$_flake_path" push
fi

unset _flake_path _host _pub_src _pub_dst
