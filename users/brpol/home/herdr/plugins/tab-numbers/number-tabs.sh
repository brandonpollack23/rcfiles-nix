#!/bin/sh
# Rename every tab to "<position>:<name>" so the tab bar shows the same number
# that prefix+1..9 uses. Herdr has no built-in tab-number label option; the
# label is the only text the tab bar renders, so the number goes in the label.
set -eu

HERDR="${HERDR_BIN_PATH:-herdr}"
TAB="$(printf '\t')"

"$HERDR" workspace list | jq -r '.result.workspaces[].workspace_id' | while read -r ws; do
  "$HERDR" tab list --workspace "$ws" |
    jq -r '.result.tabs | to_entries[] | "\(.key + 1)\t\(.value.tab_id)\t\(.value.label)"' |
    while IFS="$TAB" read -r pos id label; do
      # Strip any number we (or Herdr's unnamed-tab default) already put there.
      case "$label" in
        [0-9]*:*) base="${label#*:}" ;;
        *[!0-9]*) base="$label" ;;      # a real name with no numeric prefix
        *)        base="" ;;            # unnamed tab: label is just its number
      esac
      if [ -n "$base" ]; then
        want="$pos:$base"
      else
        want="$pos"
      fi
      [ "$label" = "$want" ] || "$HERDR" tab rename "$id" "$want"
    done
done
