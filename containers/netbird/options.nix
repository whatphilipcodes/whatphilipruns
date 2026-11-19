{ lib, ... }:
{
  options.my.netbird = {
    domain = lib.mkOption {
      type = lib.types.str;
      example = "netbird.my-domain.com";
      description = ''
        FQDN of the NetBird server. Its DNS records must point at this host so
        Let's Encrypt can issue a certificate.
      '';
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email address for Let's Encrypt certificate notifications.";
    };

    images = {
      server = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/netbirdio/netbird-server:latest";
        description = ''
          Combined management, signal, relay and STUN server. Use a release
          new enough to support all three secret environment overrides; this
          module is based on the v0.83.1 combined-server config or newer.
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
          Reverse proxy. Needs v3.7.13 or newer for aliasHeadersStrategy and
          its header-sanitization fix.
        '';
      };
    };

  };
}
