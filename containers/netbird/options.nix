{ lib, ... }:
{
  options.my.netbird = {
    domain = lib.mkOption {
      type = lib.types.str;
      example = "netbird.my-domain.com";
      description = ''
        Public FQDN of the NetBird dashboard and management server.
      '';
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email address for Let's Encrypt certificate notifications.";
    };

    network.subnet = lib.mkOption {
      type = lib.types.str;
      default = "10.89.0.0/24";
      example = "10.90.0.0/24";
      description = ''
        Dedicated rootless Podman bridge subnet used by the NetBird stack.
        Choose a subnet that does not overlap host, LAN, NetBird, or other
        Podman networks. It is also used as the trusted-proxy CIDR for Traefik.
      '';
    };

    auth.localAuthDisabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Disable NetBird's local email/password authentication after an external
        identity provider has been configured, tested, and promoted to Owner.
        This does not replace the embedded IdP issuer; it disables local login
        while leaving configured external OIDC providers available.
      '';
    };

    proxy = {
      domain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "proxy.my-domain.com";
        description = ''
          Base domain advertised by the self-hosted NetBird reverse-proxy
          cluster. Defaults to "proxy.<my.netbird.domain>".
          Create A/AAAA records for this name and a wildcard CNAME for
          "*.<domain>" pointing back to this base domain.
        '';
      };

      wireguardPort = lib.mkOption {
        type = lib.types.port;
        default = 51820;
        description = ''
          Fixed UDP WireGuard port used by the reverse proxy's embedded
          NetBird client. The port is published on the host.
        '';
      };

      externalIPMap = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "203.0.113.10";
        description = ''
          Optional public address advertised by the proxy for direct
          peer-to-peer connectivity. Set this to the server's public IP if
          STUN detection advertises an unusable private address. An optional
          internal address/interface can be appended as public/internal.
        '';
      };

      additionalPublishPorts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "5432:5432/tcp" "5353:5353/udp" ];
        description = ''
          Additional Podman host port mappings for TCP/UDP Layer-4 reverse
          proxy services created in the NetBird dashboard. HTTP and TLS
          services use the existing public TCP port 443 and need no extra
          mapping. Each entry uses Podman PublishPort syntax.
        '';
      };
    };

    images = {
      server = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/netbirdio/netbird-server:latest";
        description = ''
          Combined management, signal, relay and STUN server. Use a release
          new enough to support the secret environment overrides documented
          by the combined-server configuration.
        '';
      };

      dashboard = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/netbirdio/dashboard:latest";
        description = "Web dashboard.";
      };

      traefik = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/library/traefik:v3.7.14";
        description = ''
          External reverse proxy. Needs v3.7.13 or newer for aliasHeadersStrategy
          and TLS passthrough support used by the NetBird proxy integration.
        '';
      };

      proxy = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/netbirdio/reverse-proxy:latest";
        description = "NetBird self-hosted reverse-proxy service.";
      };

      crowdsec = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/crowdsecurity/crowdsec:v1.8.1";
        description = ''
          CrowdSec Local API used by the NetBird proxy's IP reputation bouncer.
          v1.8.1 is the version validated by the current NetBird self-hosting
          upgrade documentation.
        '';
      };
    };
  };
}
