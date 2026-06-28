# Ensure the gh CLI is authenticated to github.com over SSH. Idempotent; takes
# no arguments. Opens a web login flow when not already authenticated.
if [ "$#" -ne 0 ]; then
  echo "usage: ensure-gh-auth" >&2
  exit 2
fi

if gh auth status --hostname github.com >/dev/null 2>&1; then
  echo "Already authenticated with github.com, skipping login." >&2
  exit 0
fi
gh auth login \
  --hostname github.com \
  --git-protocol ssh \
  --web
