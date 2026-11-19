# NetBird Quadlet module

This directory splits the NetBird deployment into focused Nix modules and standalone YAML templates.

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
└── traefik/
    ├── default.nix
    ├── static.yaml
    └── dynamic.yaml
```

`default.nix` composes the modules. YAML remains in `.yaml` files and is read by Nix; only public placeholders such as the domain and internal port are substituted at build time.

## Podman secrets

The module uses Podman's native secret store; it does not require SOPS, `/run/secrets`, plaintext secret files, or secret values in the Nix store.

Before the `netbird-server` container is created, its user-level `ExecStartPre` script checks the rootless Podman store for each secret. If a secret is missing, it generates a cryptographically random value with OpenSSL and pipes it directly into `podman secret create` via stdin:

- `netbird-auth-secret` → `NB_AUTH_SECRET`
- `netbird-store-encryption-key` → `NB_STORE_ENCRYPTION_KEY`
- `netbird-session-cookie-key` → `NB_IDP_SESSION_COOKIE_ENCRYPTION_KEY`

The script deliberately does **not** use `--replace`: generated values must remain stable across restarts and NixOS rebuilds. Existing Podman secrets are left untouched. If creation is interrupted partway through, the next start preserves the secrets already created and creates only the missing ones.

Quadlet's native `Secret=` entries inject those Podman secrets as environment variables. Podman manages the values in the rootless store belonging to the user selected by `containers.uid`; make sure the user manager is enabled at boot (for example, via `linger = true`).

The server image must support these NetBird environment overrides. `NB_AUTH_SECRET` and `NB_STORE_ENCRYPTION_KEY` require NetBird v0.83.0 or newer. The session-cookie variable is documented by the combined-server configuration. Pin a compatible image version for production rather than relying on `latest`.

### First start

No manual secret provisioning is required. After applying the NixOS configuration, start the server unit as the rootless Podman owner:

```sh
systemctl --user reset-failed netbird-server.service
systemctl --user start netbird-server.service
podman secret ls
```

Expected names are `netbird-auth-secret`, `netbird-store-encryption-key`, and `netbird-session-cookie-key`.

### Persistence and backups

Podman secrets are per Podman store. These units use the rootless store of the configured container owner, not the rootful store. Running `sudo podman secret ls` inspects a different store and will not show these secrets.

The default Podman `file` secret driver stores secret contents in read-protected files; it does **not** encrypt those files at rest. Use host full-disk encryption and protect the container owner's account and storage. Podman also supports a GPG-backed `pass` driver, which can encrypt secret data independently, but requires configuring GPG for the same rootless user.

Back up the rootless Podman storage and the NetBird data volume together, or keep a separately protected recovery copy of the generated keys. In particular, losing `netbird-store-encryption-key` while retaining the NetBird database makes encrypted values in that database unreadable. Do not delete/recreate these Podman secrets casually. The same applies to restoring the database without restoring the matching secret.

Secret changes are applied when the container is recreated. Do not rotate the store encryption key after data has been written unless following NetBird's documented key-rotation/migration procedure.

## Other persistent data

- `netbird-data.volume` stores NetBird's database and state; back it up.
- `netbird-letsencrypt.volume` remains a writable volume because Traefik must update `acme.json` as certificates are issued and renewed.

## Quadlet-Nix API note

The original module uses native PascalCase keys such as `containerConfig.Image`, `podConfig.Network`, and `volumeConfig.Label`. This refactor preserves that API, which matches `mirkolenz/quadlet-nix`. The `SEIAROTg/quadlet-nix` implementation uses a different typed lower-camel-case interface; do not mix the two APIs. The import path `../../modules/virtualisation/quadlet.nix` assumes the local Quadlet module is the same one used by the original configuration.
