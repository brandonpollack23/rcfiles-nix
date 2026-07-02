# Register this host's SSH-derived age key in .sops.yaml and re-encrypt the
# secrets file for the updated recipient list. Takes no arguments. Repo location
# is injected via RCFILES_CHECKOUT_DIR.
if [ "$#" -ne 0 ]; then
  echo "usage: update-secret-keys" >&2
  exit 2
fi

export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

_repo="$HOME/$RCFILES_CHECKOUT_DIR"
SOPS_YAML="$_repo/.sops.yaml"
ensure-age-key

# The host *public* key is world-readable (mode 0644), so no sudo is needed.
HOST_AGE_KEY=$(ssh-to-age </etc/ssh/ssh_host_ed25519_key.pub)
export HOST_AGE_KEY
HOST_NAME=$(uname -n)
export HOST_NAME

# Expect exactly one age recipient list. A repo with several creation rules or
# key groups is ambiguous — we can't know which list to amend, so refuse rather
# than guess and silently corrupt access control.
_age_lists=$(yq '[.creation_rules[].key_groups[].age | select(. != null)] | length' "$SOPS_YAML")
if [ "$_age_lists" != "1" ]; then
  echo "error: expected exactly one age recipient list in $SOPS_YAML, found $_age_lists; refusing to edit" >&2
  exit 1
fi

if yq -e '.creation_rules[].key_groups[].age[] | select(. == strenv(HOST_AGE_KEY))' "$SOPS_YAML" >/dev/null 2>&1; then
  echo "Host age key already present in $SOPS_YAML, nothing to add." >&2
else
  # Append the key to the single age list and annotate it with the hostname.
  yq -i '(.creation_rules[].key_groups[] | select(has("age")) | .age) += [strenv(HOST_AGE_KEY)]' "$SOPS_YAML"
  yq -i '(.creation_rules[].key_groups[].age[] | select(. == strenv(HOST_AGE_KEY))) line_comment = strenv(HOST_NAME)' "$SOPS_YAML"
fi

# Pass the repo's .sops.yaml explicitly so this works regardless of $PWD.
exec sops --config "$SOPS_YAML" updatekeys "$_repo/secrets/secrets.yaml"
