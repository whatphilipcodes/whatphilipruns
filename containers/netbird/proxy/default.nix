{ config, lib, pkgs, ... }:
let
  common = import ../common.nix { inherit config; };
  inherit (common) cfg containers ports proxyDomain;

  podman = "${config.virtualisation.quadlet.podman}/bin/podman";

  ensureProxyToken = pkgs.writeShellScript "netbird-proxy-ensure-token" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnused ]}:$PATH

    podman=${lib.escapeShellArg podman}
    serverContainer="systemd-netbird-server"
    secretName="netbird-proxy-token"

    # Podman secrets are persistent in the rootless user's secret store. Keep
    # an existing token: creating another token on every restart would leak
    # management-side credentials and break the proxy after token replacement.
    if "$podman" secret inspect "$secretName" >/dev/null 2>&1; then
      echo "Podman secret '$secretName' already exists; preserving it." >&2
      exit 0
    fi

    echo "Creating a management-wide NetBird reverse-proxy token..." >&2

    # The NetBird server shares this pod's network namespace and its Quadlet
    # container name is systemd-netbird-server. It may still be initializing
    # when this unit starts, so retry until the admin CLI can reach its store.
    last_error=""
    for attempt in $(seq 1 60); do
      if output=$("$podman" exec "$serverContainer" \
        /go/bin/netbird-server --config /etc/netbird/config.yaml \
        admin token create --name "netbird-proxy" 2>&1); then
        token=$(printf '%s\n' "$output" \
          | sed -n 's/^[[:space:]]*Token:[[:space:]]*//p' \
          | tail -n 1)

        # NetBird's one-time plaintext token has the nbx_ prefix and is 40
        # characters. The separate Token ID is shorter and cannot authenticate.
        if [ "''${token#nbx_}" = "$token" ] || [ ''${#token} -ne 40 ]; then
          echo "NetBird admin CLI succeeded, but did not return the expected 40-character nbx_ token." >&2
          echo "Refusing to store a token ID or malformed value as NB_PROXY_TOKEN." >&2
          exit 1
        fi

        printf '%s' "$token" | "$podman" secret create "$secretName" - >/dev/null
        unset token output
        echo "Created Podman secret '$secretName' from the NetBird management token." >&2
        exit 0
      fi

      last_error="$output"
      sleep 2
    done

    echo "Could not create the NetBird proxy token after 60 attempts." >&2
    echo "Last management CLI error: $last_error" >&2
    exit 1
  '';

  proxyEnvironment = {
    # Management gRPC is local to the shared pod network namespace.
    NB_PROXY_DOMAIN = proxyDomain;
    NB_PROXY_MANAGEMENT_ADDRESS = "http://127.0.0.1:${toString ports.server}";
    NB_PROXY_ALLOW_INSECURE = "true";

    # Traefik is on the same pod network namespace. It listens on 8444 and
    # forwards TLS passthrough connections to this proxy on 8443.
    NB_PROXY_ADDRESS = ":${toString ports.proxy}";
    NB_PROXY_CERTIFICATE_DIRECTORY = "/certs";
    NB_PROXY_ACME_CERTIFICATES = "true";
    NB_PROXY_ACME_CHALLENGE_TYPE = "tls-alpn-01";
    NB_PROXY_FORWARDED_PROTO = "https";

    # Preserve the client IP in Traefik's PROXY protocol v2 hop. Since the
    # backend is reached via 127.0.0.1 inside a shared pod namespace, that is
    # the source address the proxy should trust.
    NB_PROXY_PROXY_PROTOCOL = "true";
    NB_PROXY_TRUSTED_PROXIES = "127.0.0.1/32";

    NB_PROXY_WG_PORT = toString ports.proxyWireguard;
    NB_PROXY_LOG_LEVEL = "info";
  } // lib.optionalAttrs (cfg.proxy.externalIPMap != null) {
    NB_PROXY_EXTERNAL_IP_MAP = cfg.proxy.externalIPMap;
  };
in
{
  virtualisation.quadlet.containers.netbird-proxy = {
    uid = containers.uid;
    containerConfig = {
      Image = cfg.images.proxy;
      AutoUpdate = "registry";
      Pod = "netbird.pod";
      Environment = proxyEnvironment;
      Volume = [
        "netbird-proxy-certs.volume:/certs"
      ];
      Secret = [
        "netbird-proxy-token,type=env,target=NB_PROXY_TOKEN"
      ];
    };

    # Generate a management-issued token once, then preserve it in the rootless
    # Podman secret store across container restarts and registry auto-updates.
    serviceConfig.ExecStartPre = "${ensureProxyToken}";
    unitConfig = {
      Requires = [ "netbird-server.service" ];
      After = [ "netbird-server.service" ];
    };
  };
}
