# Tests for seed-rcfiles-from-nix-store, the script used by the
# cloneRcfiles home-manager activation to seed ~/rcfiles-nix from the
# Nix closure on a fresh machine.
#
# Run via: nix flake check --print-build-logs
{pkgs}: let
  fakeSrc = pkgs.runCommand "fake-rcfiles-src" {} ''
    mkdir -p $out
    echo '# placeholder' > $out/flake.nix
    echo 'readme' > $out/README.md
  '';

  seedScript = import ../users/brpol/home/scripts/seed-rcfiles-from-nix-store.nix {inherit pkgs;};
in
  pkgs.runCommand "test-rcfiles-seeding"
  {nativeBuildInputs = [pkgs.git pkgs.rsync];}
  ''
    HOME=$TMPDIR/home
    mkdir -p "$HOME"

    # ── Test 1: fresh destination is seeded from fakeSrc ─────────────────────
    ${seedScript}/bin/seed-rcfiles-from-nix-store "$HOME/rcfiles-nix" "${fakeSrc}"

    test -f "$HOME/rcfiles-nix/flake.nix" \
      || { echo "FAIL: flake.nix not copied"; exit 1; }
    test -d "$HOME/rcfiles-nix/.git" \
      || { echo "FAIL: .git not initialised"; exit 1; }

    _remote=$(git -C "$HOME/rcfiles-nix" remote get-url origin)
    test "$_remote" = "https://github.com/brandonpollack23/rcfiles-nix.git" \
      || { echo "FAIL: wrong remote: $_remote"; exit 1; }

    # ── Test 2: idempotent — existing .git skips re-seeding ──────────────────
    echo "local-edit" > "$HOME/rcfiles-nix/flake.nix"
    ${seedScript}/bin/seed-rcfiles-from-nix-store "$HOME/rcfiles-nix" "${fakeSrc}"
    grep -q "local-edit" "$HOME/rcfiles-nix/flake.nix" \
      || { echo "FAIL: existing repo was overwritten by re-seed"; exit 1; }

    touch $out
  ''
