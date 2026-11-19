{ config, ... }:
let
  common = import ./common.nix { inherit config; };
  inherit (common) cfg containers;
in
{
  virtualisation.quadlet.containers.netbird-dashboard = {
    uid = containers.uid;
    containerConfig = {
      Image = cfg.images.dashboard;
      AutoUpdate = "registry";
      Pod = "netbird.pod";
      Environment = {
        # Endpoints
        NETBIRD_MGMT_API_ENDPOINT = "https://${cfg.domain}";
        NETBIRD_MGMT_GRPC_API_ENDPOINT = "https://${cfg.domain}";

        # OIDC: use the embedded IdP.
        AUTH_AUDIENCE = "netbird-dashboard";
        AUTH_CLIENT_ID = "netbird-dashboard";
        AUTH_CLIENT_SECRET = "";
        AUTH_AUTHORITY = "https://${cfg.domain}/oauth2";
        USE_AUTH0 = "false";
        AUTH_SUPPORTED_SCOPES = "openid profile email groups";
        AUTH_REDIRECT_URI = "/nb-auth";
        AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";

        # TLS is terminated by Traefik.
        NGINX_SSL_PORT = "443";
        LETSENCRYPT_DOMAIN = "none";
      };
    };
  };
}
