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

# jj auto-tracks new/modified files; check if the working copy sees a diff.
if [ -z "$(jj -R "$_flake_path" diff --summary -- "hosts/$_host/user.pub")" ]; then
  echo "Key already committed for $_host, nothing to do." >&2
else
  jj -R "$_flake_path" commit -m "feat: register SSH public key for $_host"
  # Advance the master bookmark to the new commit (@-) and push.
  jj -R "$_flake_path" bookmark set master -r "@-"
  jj -R "$_flake_path" git fetch
  jj -R "$_flake_path" rebase -d "master@origin"
  jj -R "$_flake_path" bookmark set master -r "@-"
  jj -R "$_flake_path" git push --bookmark master
fi

unset _flake_path _host _pub_src _pub_dst
