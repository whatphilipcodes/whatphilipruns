# NetBird Quadlet module

This directory defines the NetBird combined server, dashboard, Traefik and the
self-hosted NetBird reverse-proxy service as separate rootless Quadlet
containers inside one Podman pod.

## Layout

```text
containers/netbird/
├── default.nix
├── options.nix
├── assertions.nix
├── common.nix
├── network.nix
├── volumes.nix
├── podman-secrets.nix
├── dashboard.nix
├── server/
│   ├── default.nix
│   └── config.yaml
├── traefik/
│   ├── default.nix
│   ├── static.yaml
│   └── dynamic.yaml
└── proxy/
    └── default.nix
```

## Pod layout and ports

All containers join `netbird.pod` and share its network namespace. This is
important for the loopback connections between the services:

- NetBird server: `127.0.0.1:8081`
- Dashboard: `127.0.0.1:80`
- NetBird proxy: `127.0.0.1:8443`
- Traefik HTTPS entrypoint: `:8444`, published by the pod as host TCP/443

Traefik cannot keep using 8443 internally because the NetBird proxy also listens
on 8443. The pod therefore publishes host port 443 to Traefik's internal 8444.
Traefik passes TLS for every SNI hostname except `my.netbird.domain` through to
the NetBird proxy. It does not terminate TLS for those proxy service domains.

The pod publishes:

- TCP 80 → Traefik HTTP redirect entrypoint
- TCP 443 → Traefik HTTPS entrypoint
- UDP 3478 → NetBird STUN
- UDP `my.netbird.proxy.wireguardPort` (51820 by default) → proxy WireGuard
- Any entries in `my.netbird.proxy.additionalPublishPorts` for Layer-4 TCP/UDP
  services created in the dashboard

## Options

The host configuration must set the regular NetBird domain and ACME email:

```nix
my.netbird = {
  domain = "netbird.example.com";
  acmeEmail = "admin@example.com";

  # Optional; defaults to "proxy." + domain above.
  proxy.domain = "proxy.example.com";

  # Optional: useful when peers cannot discover the proxy's public address via
  # STUN. Leave unset to let the embedded NetBird client discover it.
  # proxy.externalIPMap = "203.0.113.10";

  # Optional mappings for TCP/UDP Layer-4 services created in the dashboard.
  # proxy.additionalPublishPorts = [ "5432:5432/tcp" ];
};
```

For a host domain of `netbird.example.com`, the default proxy base domain is
`proxy.netbird.example.com`. A dedicated domain such as `proxy.example.com` is
also supported and is generally easier to manage alongside other DNS records.

## DNS and firewall

For `my.netbird.proxy.domain = "proxy.example.com"`, create:

| Type | Name | Target |
|---|---|---|
| A | `proxy.example.com` | Server public IPv4 |
| AAAA | `proxy.example.com` | Server public IPv6 (if working end-to-end) |
| CNAME | `*.proxy.example.com` | `proxy.example.com` |

Use the actual `proxy.domain` value. The wildcard record is needed so service
hostnames such as `app.proxy.example.com` resolve to the server. The base record
is also required; the wildcard does not cover the bare base domain.

Allow these inbound ports in the Hetzner firewall and the host firewall:

- TCP 80 and 443
- UDP 3478 (NetBird STUN)
- UDP 51820 by default (proxy WireGuard; change this if
  `proxy.wireguardPort` is changed)
- Any custom TCP/UDP ports you configure in `proxy.additionalPublishPorts`

HTTP and TLS reverse-proxy services use TCP 443 and need no additional ports.
TCP/UDP Layer-4 services need their service ports published in
`proxy.additionalPublishPorts` and opened in both firewalls.

The proxy uses Let's Encrypt TLS-ALPN-01. Public TCP/443 must reach Traefik,
which must pass the `acme-tls/1` ALPN challenge through to the proxy for its
service hostnames. Do not put a TLS-terminating CDN/proxy in front unless it
preserves this ALPN protocol.

## Podman secrets

The module uses Podman's native secret store. It does not use SOPS, `/run/secrets`,
plaintext secret files, or secret values in the Nix store.

Before the NetBird server container starts, `podman-secrets.nix` checks the
rootless Podman store and creates three random values only if they are missing:

- `netbird-auth-secret` → `NB_AUTH_SECRET`
- `netbird-store-encryption-key` → `NB_STORE_ENCRYPTION_KEY`
- `netbird-session-cookie-key` → `NB_IDP_SESSION_COOKIE_ENCRYPTION_KEY`

The reverse-proxy access token is also managed automatically. Before the
proxy container is created, its `ExecStartPre` script:

1. Checks the rootless Podman secret store for `netbird-proxy-token`.
2. If missing, waits for the combined NetBird server to be ready and runs
   `netbird-server admin token create --name netbird-proxy` inside it.
3. Extracts and validates the one-time plaintext `nbx_...` token (40 characters),
   then pipes it directly into `podman secret create`.
4. Preserves the secret on subsequent starts and image updates. It never prints
   the token or puts it in the Nix store.

The script intentionally creates a non-expiring management-wide token. The
management token can be revoked independently with the NetBird admin CLI; back
up the Podman secret store alongside the NetBird database.

### First deployment and token recovery

After applying the NixOS configuration, start the proxy as the rootless Podman
owner (not with `sudo`):

```sh
systemctl --user reset-failed netbird-proxy.service
systemctl --user start netbird-proxy.service
journalctl --user -u netbird-proxy.service -f
```

Verify the secret exists without printing its value:

```sh
podman secret ls
```

If an earlier manual attempt stored the 20-character Token ID instead of the
one-time `nbx_...` plaintext token, stop the proxy and remove that invalid
secret once. The next start will automatically issue a fresh management token
and create the Podman secret correctly:

```sh
systemctl --user stop netbird-proxy.service
podman secret rm netbird-proxy-token
systemctl --user reset-failed netbird-proxy.service
systemctl --user start netbird-proxy.service
```

Do not remove the three NetBird server secrets. This procedure only replaces
the proxy access token. The proxy uses the management-wide self-hosted token
model; the Dashboard's “Setup Self-Hosted Cluster” wizard creates a different,
account-scoped BYOP token and is not needed for this configuration.

## Peer-to-peer connectivity

The module configures a fixed UDP WireGuard port (51820 by default) and publishes
it. The proxy may still use relayed connectivity if STUN cannot discover a
usable public address. If `netbird status -d` on a peer shows the proxy peer as
`Relayed` and you want direct peer-to-peer connectivity, set
`my.netbird.proxy.externalIPMap` to the server's public IP (or
`public-IP/internal-IP-or-interface`), confirm the same UDP port is reachable,
and rebuild.

## Automatic updates

The server, dashboard, Traefik and NetBird proxy containers have
`AutoUpdate = "registry"`. Podman's user-level auto-update timer must be enabled
for the `podman` user. Traefik remains pinned to its configured numeric tag;
auto-update follows that tag rather than changing major/minor versions.

## Persistence and backups

- `netbird-data.volume` stores the NetBird database and state.
- `netbird-letsencrypt.volume` stores Traefik's writable `acme.json`.
- `netbird-proxy-certs.volume` stores certificates managed by the NetBird proxy.
- Rootless Podman secrets belong to the Podman owner's store.

Back up Podman storage/secrets, all three volumes, and the host configuration
together. In particular, losing `netbird-store-encryption-key` while retaining
the database makes encrypted database values unreadable. Losing the proxy
access token can be repaired by issuing a new management token; losing the
management database's token registration requires revoking/reissuing it.

Podman's default `file` secret driver restricts file permissions but does not
encrypt secret contents at rest. Protect the host storage (ideally with full-disk
encryption) and the `podman` account.

## Quadlet-Nix API note

The module uses native PascalCase Quadlet keys such as `containerConfig.Image`,
`podConfig.Network` and `volumeConfig.Label`, consistent with the same
`mirkolenz/quadlet-nix`-style API used by the original module. Do not mix these
with a different quadlet-nix implementation that expects typed lower-camel-case
attributes.
