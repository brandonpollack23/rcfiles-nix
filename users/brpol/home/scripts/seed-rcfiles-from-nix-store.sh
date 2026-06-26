_dest="$1"
_src="$2"

if [ ! -d "$_dest/.git" ]; then
  rsync -rlpt --chmod=u+rwX "$_src/" "$_dest/"
  git -C "$_dest" init -q
  git -C "$_dest" remote add origin \
    https://github.com/brandonpollack23/rcfiles-nix.git
fi
