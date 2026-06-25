# Tests for lib/resolve-host-keys.nix.
# Run via: nix flake check --print-build-logs
{pkgs}: let
  lib = pkgs.lib;
  resolveHostKeys = import ../lib/resolve-host-keys.nix {inherit lib;};

  mockKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAImockkeymockkeymockkeymockkeymock brpol@mock";

  mockRegistry = {
    "host-with-key" = mockKey;
    "host-no-pub" = null; # known host, user.pub not yet committed
    # "unknown-host" intentionally absent
  };

  resolve = allowedSSHHosts:
    resolveHostKeys {
      hostname = "testhost";
      inherit allowedSSHHosts;
      hostUserKeys = mockRegistry;
    };

  checks = [
    # Known host with a committed key → key appears in the result.
    (lib.assertMsg
      (resolve ["host-with-key"] == [mockKey])
      "known host with key should appear in the resolved list")

    # Known host without user.pub → empty result (lib.warn emitted to stderr).
    (lib.assertMsg
      (resolve ["host-no-pub"] == [])
      "known host without user.pub should resolve to empty (warning expected on stderr)")

    # Mixed list → only the host with a real key contributes.
    (lib.assertMsg
      (resolve ["host-with-key" "host-no-pub"] == [mockKey])
      "only hosts with committed keys should appear in a mixed list")

    # Unknown host (not in the registry at all) → throw is caught by tryEval.
    (lib.assertMsg
      (!(builtins.tryEval (resolve ["unknown-host"])).success)
      "host with no meta.nix must throw an error")
  ];
in
  assert builtins.all (x: x) checks;
    pkgs.runCommand "test-ssh-keyring" {} "touch $out"
