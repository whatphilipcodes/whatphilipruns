# NetBird Quadlet module

This directory defines the NetBird combined server, dashboard, self-hosted
reverse proxy, and CrowdSec as separate rootless Quadlet containers on a
Quadlet-managed Podman bridge network. Traefik and Pocket ID are maintained in
their own directories but join the same DNS-enabled bridge.

## Layout

```text
containers/
├── netbird/
│   ├── default.nix
│   ├── options.nix
│   ├── assertions.nix
│   ├── common.nix
│   ├── network.nix
│   ├── volumes.nix
│   ├── podman-secrets.nix
│   ├── dashboard.nix
│   ├── server/       # NetBird combined-server + YAML config
│   ├── proxy/        # NetBird reverse proxy + token provisioning
│   └── crowdsec/     # CrowdSec LAPI
├── traefik/          # Shared ingress and routes
└── pocket-id/        # Optional OIDC provider
```

## Network topology and ports

All containers have independent network namespaces and attach to the
Quadlet-managed `netbird.network` bridge. Podman's DNS aliases provide stable
service discovery:

- `netbird-server:8081` — Management, Signal, relay HTTP/gRPC backend
- `netbird-dashboard:80` — dashboard
- `netbird-proxy:8443` — TLS-passthrough backend
- `netbird-crowdsec:8080` — CrowdSec Local API (not published)
- `pocket-id:1411` — Pocket ID HTTP backend (not published)
- `traefik` — shared ingress container

The default bridge subnet is `10.89.0.0/24`. Change it with
`my.netbird.network.subnet` if it overlaps a LAN, NetBird, host, or other
Podman route. The same subnet is used as the trusted-proxy range for NetBird,
NetBird Proxy, and Pocket ID. Only containers attached to this dedicated
network are inside that trust boundary.

Published ports are deliberately owned by the container that listens on them:

- Traefik: TCP 80 and 443
- NetBird combined server: UDP 3478 (STUN; must be reachable directly)
- NetBird reverse proxy: UDP 51820 by default (WireGuard), plus configured
  Layer-4 service ports
- CrowdSec and Pocket ID: no host-published ports

Traefik passes service-hostname TLS through to `netbird-proxy:8443`. It
terminates TLS for the NetBird management hostname and Pocket ID. The NetBird
reverse-proxy feature requires Traefik TLS passthrough; other edge proxies are
not supported for this feature. See the NetBird documentation.

## Options

The host configuration must set the regular NetBird domain and ACME email:

```nix
my.netbird = {
  domain = "vpn.hellmar.de";
  acmeEmail = "admin@hellmar.de";

  # Use the root domain for service subdomains such as homeassistant.hellmar.de.
  proxy.domain = "hellmar.de";

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
`proxy.additionalPublishPorts` on the NetBird proxy container and opened in both firewalls.

The proxy uses Let's Encrypt TLS-ALPN-01. Public TCP/443 must reach Traefik,
which passes the `acme-tls/1` ALPN challenge through to the proxy for its
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


## CrowdSec IP reputation

The module adds a CrowdSec LAPI container (`crowdsecurity/crowdsec:v1.8.1`)
on the dedicated bridge. It persists `/etc/crowdsec` and `/var/lib/crowdsec/data`,
installs `crowdsecurity/linux`, and exposes its LAPI only as
`netbird-crowdsec:8080` on the bridge (no host port is published).

The proxy and CrowdSec each have their own network namespace, so both may use
port 8080 without a bind conflict. The proxy keeps its default local health
probe listener; CrowdSec LAPI is separately reachable as `netbird-crowdsec:8080`
on the bridge.

The proxy's startup preparation script now manages two separate credentials:

- `netbird-proxy-token`: the NetBird management-issued proxy token.
- `netbird-crowdsec-bouncer-key`: the CrowdSec LAPI bouncer API key.

If the CrowdSec bouncer secret is missing, the script waits for
`cscli lapi status`, deletes any orphaned `netbird-proxy` bouncer registration
left behind by a lost secret, creates a fresh bouncer key with
`cscli bouncers add netbird-proxy -o raw`, and pipes it directly into the
rootless Podman secret store. The proxy receives it as
`NB_PROXY_CROWDSEC_API_KEY`; it reaches LAPI at
`NB_PROXY_CROWDSEC_API_URL=http://netbird-crowdsec:8080`.

After deployment, verify:

```sh
podman exec systemd-netbird-crowdsec cscli lapi status
podman exec systemd-netbird-crowdsec cscli bouncers list
podman secret ls
```

The proxy advertises CrowdSec support once it has the LAPI URL and key. In the
NetBird dashboard, configure CrowdSec individually for each reverse-proxy
service under **Access Control**. Start with **Observe**; switch to **Enforce**
after reviewing verdicts. In enforce mode, a proxy whose bouncer has not
completed its initial sync denies connections (fail-closed).

**Log collection caveat:** This deployment currently uses CrowdSec for the
community IP-reputation blocklist. It installs `crowdsecurity/linux`, but does
not mount host SSH/syslog logs into the container. Therefore that collection
will not generate local SSH/syslog detections until log sources and matching
acquisition configuration are deliberately added. CrowdSec's community
blocklist remains available without local log sources. Optional CrowdSec
Console enrollment is also not required.

CrowdSec AppSec for the NetBird dashboard, `/api`, and `/oauth2` is a separate
integration and is intentionally not enabled here. Its failure behavior can
block dashboard access, so it should be designed and tested separately.

## Automatic updates

The server, dashboard, Traefik, NetBird proxy and CrowdSec containers have
`AutoUpdate = "registry"`. Podman's user-level auto-update timer must be enabled
for the `podman` user. Traefik remains pinned to its configured numeric tag;
CrowdSec is pinned to the currently validated `v1.8.1` tag.

## Persistence and backups

- `netbird-data.volume` stores the NetBird database and state.
- `netbird-letsencrypt.volume` stores Traefik's writable `acme.json`.
- `netbird-proxy-certs.volume` stores certificates managed by the NetBird proxy.
- `netbird-crowdsec-config.volume` stores CrowdSec configuration and credentials.
- `netbird-crowdsec-data.volume` stores the CrowdSec database and downloaded data.
- Rootless Podman secrets belong to the Podman owner's store.

Back up Podman storage/secrets, all persistent volumes, and the host configuration
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


## Shared Traefik and Pocket ID

Traefik is maintained in the separate `containers/traefik/` directory and
runs as an independent container on the dedicated `netbird.network` bridge.
This lets the same public ingress serve the
NetBird dashboard, NetBird reverse-proxy passthrough, and optional HTTP services
such as Pocket ID. Traefik's file provider watches a directory containing a
NetBird route fragment and, when enabled, a Pocket ID route fragment.

Pocket ID is optional and lives in `containers/pocket-id/`. Import it alongside
this NetBird module and enable it with:

```nix
my.pocketId = {
  enable = true;
  domain = "id.hellmar.de";
};
```

The Pocket ID host must be excluded from the NetBird proxy's catch-all TCP
TLS-passthrough rule. The shared Traefik module does this automatically when
Pocket ID is enabled. It then terminates HTTPS for `id.hellmar.de` and forwards
plain HTTP to Pocket ID on `pocket-id:1411`. NetBird Management resolves the
Pocket ID issuer hostname to Traefik's network alias, so the internal issuer
lookup traverses the normal TLS router without public-IP hairpinning. The HTTP
router and NetBird reverse-proxy TCP passthrough can share the same entrypoint:
Traefik tries TCP routers first and falls back to HTTP routers when no TCP rule
matches.

Pocket ID's encryption key is generated once into the rootless Podman secret
store. Its SQLite database and uploads are stored in the `pocket-id-data` volume.
Back up these together; losing the encryption key can make encrypted Pocket ID
data unreadable.


## Dedicated rootless bridge network

All services now use the Quadlet-managed `netbird.network` bridge instead of
a shared `netbird.pod`. Each container has its own network namespace, while
Podman DNS aliases provide service discovery. The default subnet is
`10.89.0.0/24`, configurable with
`my.netbird.network.subnet` if it overlaps another host, LAN, NetBird, or
Podman network. Podman DNS aliases provide stable names between containers.

The Traefik container is the only container publishing TCP 80/443. The
NetBird server publishes UDP 3478 directly for STUN, and the NetBird proxy
publishes its WireGuard UDP port (51820 by default) plus any configured Layer-4
ports. CrowdSec and Pocket ID are not published to the host.

### Rootless source-IP preservation

NetBird STUN and the NetBird proxy's PROXY-protocol/CrowdSec integration need
accurate client source addresses. Rootless bridge port forwarding uses
`rootlessport` by default, which can rewrite UDP source addresses. This module
sets `virtualisation.containers.containersConf.rootless.settings.network.rootless_port_forwarder`
to `pasta`, which uses the newer `pesto` kernel-level forwarding path, and
installs `pkgs.passt`. Podman's documentation currently marks this mode
experimental and requires a sufficiently recent `passt` package containing
`pesto`. Verify `pesto --version` on the host before deployment.

Changing `rootless_port_forwarder` must be done while no rootless Podman
containers are running for this user. Stop all containers managed by the
`podman` user during the migration, not just this stack, then restart them
after the configuration switch.

### Migrating from the old pod

The change removes `netbird.pod` and creates individual containers on
`netbird.network`. Named Podman volumes and secrets are retained; do not remove
`netbird-data`, `netbird-letsencrypt`, `netbird-proxy-certs`, either CrowdSec
volume, Pocket ID data, or any existing Podman secrets.

During a maintenance window, as the `podman` user:

1. Stop all Quadlet units in this stack and all other containers owned by this
   rootless Podman user. The rootless port-forwarder setting must not be changed
   while any of that user's containers are running.
2. Stop the old `netbird-pod.service`, then remove only the old pod:
   `podman pod rm -f systemd-netbird`. Do not remove named volumes or secrets.
3. Apply the NixOS rebuild, run `systemctl --user daemon-reload`, and start the
   independent units. The `.network` dependencies create `systemd-netbird`
   before the containers that attach to it.
4. Verify DNS from the relevant containers, for example
   `podman exec systemd-netbird-traefik getent hosts netbird-server` and
   `podman exec systemd-netbird-server getent hosts id.hellmar.de`.

This is a networking migration and will cause a brief outage. It does not
require recreating persistent volumes or regenerating Podman secrets.
