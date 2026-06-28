# Nix config

My friends [asasine](https://github.com/asasine/) and [macro](https://github.com/Axiometry) asked me about nix.

I always avoided it.

Welp.

## Architecture

- `lib/default.nix` — `mkHost` function; the single entry point for all host definitions
- `flake.nix` — auto-discovers every `hosts/<name>/` that has a `meta.nix` and calls `mkHost` for it; per-host flags and SSH keys live in that `meta.nix`, not here
- `modules/common.nix` — baseline for every host: packages, nix settings, SSH, sops secrets
- `modules/nixos.nix` — NixOS-only shared policy (store cleanup via `programs.nh`)
- `modules/darwin.nix` — Darwin-only shared policy (placeholder)
- `modules/desktop.nix` — GUI stack, gated by `enableDesktop` in `mkHost`
- `hosts/<name>/` — host-specific hardware + bootloader config
- `hosts/<name>/home-overrides/<user>/` — per-host home-manager tweaks for a user; each `.nix` file (e.g. `git.nix`) is auto-imported and merged onto the matching base module in `users/<user>/home/`
- `users/<name>/` — system-level user config (`nixos.nix`) and home-manager config (`home/`)
- `old/` — dormant code kept for reference; nothing here is imported or active

Packages from flake inputs (neovim, nixos-cli) are resolved in `lib/default.nix` and passed
via `specialArgs` — modules must not reach into `inputs` directly.

## Secrets (sops-nix)

Secrets live in `secrets/secrets.yaml`, encrypted with [sops](https://github.com/getsops/sops)
using age keys. `.sops.yaml` at the repo root defines which keys can decrypt each file.

At edit time it uses my primary age key which i keep secure in my password manager.

At NixOS activation time, sops-nix decrypts secrets using the machine's SSH host key
(`/etc/ssh/ssh_host_ed25519_key`). No manual token setup needed after first deploy.

### Secret management commands

Three commands are available on every NixOS host managed by this config. Each one
bootstraps `~/.config/sops/age/keys.txt` from a Bitwarden secure note named
`age-private-key` automatically if the file is absent.

| Command              | What it does                                                                                                                                                        |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ensure-age-key`     | Bootstraps `~/.config/sops/age/keys.txt` from Bitwarden if missing. Idempotent — safe to call at any time.                                                          |
| `edit-nix-secrets`   | Opens `~/rcfiles-nix/secrets/secrets.yaml` in `$EDITOR` via sops. Re-encrypts for all recipients on save.                                                           |
| `update-secret-keys` | Registers this machine's SSH host key in `.sops.yaml` (if absent), then re-encrypts `secrets/secrets.yaml` for all recipients. Idempotent — safe to re-run anytime. |

All three can be run from any directory.

### How `sops updatekeys` works

`sops updatekeys` re-reads `.sops.yaml` and re-encrypts the file for the **current full
recipient list**. Running it with a new host key added to `.sops.yaml` adds that host without
touching the existing recipients. Removing a key from `.sops.yaml` and re-running removes that
recipient. It requires your personal age private key to decrypt the existing ciphertext first.

### Bootstrapping a new NixOS machine

SSH host keys are generated at first boot, not at build time — so the new machine's age key
isn't known until after it has booted. The flow is:

```bash
# 1. After first boot, register this machine and re-encrypt secrets:
update-secret-keys   # converts SSH host key via ssh-to-age, adds to .sops.yaml, re-encrypts

# 2. Commit the updated .sops.yaml (the host directory is discovered
#    automatically from its meta.nix — no flake.nix edit needed), then deploy:
nrs
```

sops-nix reads the host's SSH key at activation time and decrypts secrets into
`/run/secrets/` — no personal key needed on the target machine.

### One-time personal key setup (already done)

This is how I generated my personal age keypair and added it to `.sops.yaml` as the primary, for posterity and replacement in the future.

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt   # generate keypair
age-keygen -y ~/.config/sops/age/keys.txt   # print public key → add to .sops.yaml as &primary
```

Store the `AGE-SECRET-KEY-1...` line from `keys.txt` as a **Bitwarden secure note named
`age-private-key`**. This is what `ensure-age-key` fetches to restore the key file on a
fresh machine.
