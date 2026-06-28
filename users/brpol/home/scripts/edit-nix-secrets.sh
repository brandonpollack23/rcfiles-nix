# Decrypt and open the SOPS secrets file in $EDITOR, fetching the age key first.
# Takes no arguments. Repo location is injected via RCFILES_CHECKOUT_DIR.
if [ "$#" -ne 0 ]; then
  echo "usage: edit-nix-secrets" >&2
  exit 2
fi

ensure-age-key
exec sops "$HOME/$RCFILES_CHECKOUT_DIR/secrets/secrets.yaml"
