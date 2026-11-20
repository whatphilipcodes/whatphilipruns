# Pocket ID

Pocket ID is an optional OIDC provider deployed as its own Quadlet module. It
reuses the existing Traefik container while running in its own network
namespace on the dedicated `netbird.network` bridge. Traefik reaches Pocket ID
at `pocket-id:1411` through Podman's network DNS; the application port is not
published on the host.

## Enable it

Import this module alongside the NetBird module in the WPR host configuration:

```nix
imports = [
  ../../containers/netbird
  ../../containers/pocket-id
];

my.pocketId = {
  enable = true;
  domain = "id.hellmar.de";
};
```

Adjust the relative import paths to match the host file location.

## DNS and TLS

The existing `*.hellmar.de` wildcard DNS record should already send
`id.hellmar.de` to this server when `my.netbird.proxy.domain = "hellmar.de"`.
Traefik obtains the certificate using the existing Let's Encrypt TLS challenge.
No additional host port is required.

The Traefik TCP TLS-passthrough catch-all explicitly excludes the Pocket ID
hostname; an HTTP router then terminates TLS and forwards all paths to
`http://pocket-id:1411`. The management hostname remains separately routed
to NetBird.

## Secret and persistence

Pocket ID requires `ENCRYPTION_KEY`. The service's `ExecStartPre` generates a
32-byte random base64 key once and pipes it directly into the rootless Podman
secret store as `pocket-id-encryption-key`. Quadlet mounts it at
`/run/secrets/pocket-id-encryption-key`; Pocket ID reads it through
`ENCRYPTION_KEY_FILE`. Do not remove or regenerate this secret after initial
setup: it encrypts Pocket ID's sensitive data.

The `pocket-id-data` volume stores the SQLite database and uploads. Back up the
volume and Podman secret together. Only one Pocket ID instance should use this
SQLite database at a time.

## First login

After deployment, open `https://id.hellmar.de/setup`, create the first admin
account, and register a passkey. The setup page is only available until the
first account is created.

## Reverse-proxy trust

Pocket ID trusts the dedicated NetBird bridge subnet because Traefik connects
from that network and forwards `X-Forwarded-For`, allowing Pocket ID to apply
rate limits and audit the original client IP.


## First login

After deployment, open `https://id.hellmar.de/setup`, create the first admin
account, and register a passkey. This is a one-time first-run step, not a
NixOS installation prompt. Pocket ID only serves `/setup` until its first user
exists. After signup, complete passkey registration; Pocket ID uses passkeys
for subsequent sign-ins.

If `/setup` says setup is complete, a user already exists in the persistent
`pocket-id-data` volume. If signup created the account but passkey registration
was interrupted, use the one-time login link instead of deleting the volume:

```bash
podman exec -it systemd-pocket-id \
  /app/pocket-id one-time-access-token <username-or-email>
```

The command prints a single-use link valid for one hour. Open it, then add a
passkey to the account. Treat that link like a password.

If the signup form itself fails while `/setup` is still shown, inspect:

```bash
journalctl --user -u pocket-id.service -b -n 150 --no-pager
```

Do not remove the `pocket-id-data` volume or regenerate
`pocket-id-encryption-key` as a troubleshooting step; either can destroy access
to existing Pocket ID data.
