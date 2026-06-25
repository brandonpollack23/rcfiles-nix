# Pure function: resolves a list of allowed hostnames to SSH public keys.
# Unknown hosts (no meta.nix) and hosts whose user.pub has not yet been committed
# both emit a lib.warn and contribute no key, keeping evaluation safe.
{lib}: {
  hostname,
  allowedSSHHosts,
  hostUserKeys,
}:
lib.concatMap (
  h:
    if !(hostUserKeys ? ${h})
    then
      throw
      "${hostname}: allowedSSHHosts entry '${h}' is not a known host — no hosts/${h}/meta.nix found"
    else if hostUserKeys.${h} == null
    then
      lib.warn
      "${hostname}: allowedSSHHosts entry '${h}' has no committed user.pub yet — run register-ssh-key-nix on that host and push"
      []
    else [hostUserKeys.${h}]
)
allowedSSHHosts
