# Seed a fresh rcfiles-nix checkout from a Nix store path.
# Usage: seed-rcfiles-from-nix-store <dest> <src>
#   <dest>  checkout directory to create and initialise as a jj+git repo
#   <src>   Nix store path holding the working-tree contents to copy in
# No-op if <dest> already contains a .jj directory.
if [ "$#" -ne 2 ]; then
  echo "usage: seed-rcfiles-from-nix-store <dest> <src>" >&2
  exit 2
fi
_dest="$1"
_src="$2"

if [ ! -d "$_dest/.jj" ]; then
  rsync -rlpt --chmod=u+rwX "$_src/" "$_dest/"
  jj git init --colocate "$_dest"
  jj -R "$_dest" git remote add origin "$RCFILES_REPO_URL"
fi
