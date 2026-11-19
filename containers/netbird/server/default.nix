{ config, pkgs, ... }:
let
  common = import ../common.nix { inherit config; };
  inherit (common) cfg ports containers;

  serverConfig = pkgs.writeText "netbird-config.yaml" (
    builtins.replaceStrings
      [ "@DOMAIN@" "@SERVER_PORT@" "3478 # @STUN_PORT@ is replaced by Nix" ]
      [ cfg.domain (toString ports.server) (toString ports.stun) ]
      (builtins.readFile ./config.yaml)
  );
in
{
  virtualisation.quadlet.containers.netbird-server = {
    uid = containers.uid;
    containerConfig = {
      Image = cfg.images.server;
      AutoUpdate = "registry";
      Pod = "netbird.pod";
      Exec = "--config /etc/netbird/config.yaml";
      Volume = [
        "netbird-data.volume:/var/lib/netbird"
        "${serverConfig}:/etc/netbird/config.yaml:ro"
      ];

      # Quadlet maps these to Podman's --secret arguments. NetBird reads the
      # environment overrides directly; no secret values are rendered into YAML.
      Secret = [
        "netbird-auth-secret,type=env,target=NB_AUTH_SECRET"
        "netbird-store-encryption-key,type=env,target=NB_STORE_ENCRYPTION_KEY"
        "netbird-session-cookie-key,type=env,target=NB_IDP_SESSION_COOKIE_ENCRYPTION_KEY"
      ];
    };
  };
}
