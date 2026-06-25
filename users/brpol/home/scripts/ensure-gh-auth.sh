if gh auth status --hostname github.com >/dev/null 2>&1; then
  echo "Already authenticated with github.com, skipping login." >&2
  exit 0
fi
gh auth login \
  --hostname github.com \
  --git-protocol ssh \
  --web
