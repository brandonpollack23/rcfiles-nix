# Fetch brpol's personal age private key from Bitwarden into
# ~/.config/sops/age/keys.txt if absent. Idempotent; takes no arguments.
if [ "$#" -ne 0 ]; then
  echo "usage: ensure-age-key" >&2
  exit 2
fi

KEYS_FILE="$HOME/.config/sops/age/keys.txt"
if [ -f "$KEYS_FILE" ]; then
  echo "Key file ~/.config/sops/age/keys.txt already exists, if you'd like to regenerate please remove it first"
  exit 0
fi
echo "Age key not found at $KEYS_FILE — fetching from Bitwarden..." >&2
_bw_opened=false
STATUS=$(bw status | jq -r '.status')
case "$STATUS" in
  unauthenticated)
    export BW_SESSION
    BW_SESSION=$(bw login --raw)
    _bw_opened=true
    ;;
  locked)
    export BW_SESSION
    BW_SESSION=$(bw unlock --raw)
    _bw_opened=true
    ;;
esac
# Lock on exit only if we were the ones who opened the vault; also clean up any
# leftover temp key file.
trap '[ "$_bw_opened" = true ] && bw lock >/dev/null; [ -n "${_tmp:-}" ] && rm -f "$_tmp"' EXIT
KEY=$(bw get notes "age-private-key")
if [ -z "$KEY" ]; then
  echo "error: Bitwarden note 'age-private-key' is empty or not found" >&2
  exit 1
fi
mkdir -p "$(dirname "$KEYS_FILE")"
# Write private key with a restrictive umask, into a temp file, then atomically
# rename into place so the key is never momentarily world/group-readable and a
# crash mid-write can't leave a partial keys.txt.
umask 077
_tmp=$(mktemp "$(dirname "$KEYS_FILE")/keys.txt.XXXXXX")
printf '%s\n' "$KEY" > "$_tmp"
chmod 600 "$_tmp"
mv -f "$_tmp" "$KEYS_FILE"
_tmp=""
echo "Age key saved to $KEYS_FILE" >&2
