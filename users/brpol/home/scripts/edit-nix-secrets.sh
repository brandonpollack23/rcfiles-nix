# Decrypt and open the SOPS secrets file in $EDITOR, fetching the age key first.
# Takes no arguments. Repo location is injected via RCFILES_CHECKOUT_DIR.
if [ "$#" -ne 0 ]; then
  echo "usage: edit-nix-secrets" >&2
  exit 2
fi

ensure-age-key
# Pass the repo's .sops.yaml explicitly so this works regardless of $PWD.
_repo="$HOME/$RCFILES_CHECKOUT_DIR"
exec sops --config "$_repo/.sops.yaml" "$_repo/secrets/secrets.yaml"
