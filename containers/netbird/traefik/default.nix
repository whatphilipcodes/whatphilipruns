{ config, lib, pkgs, ... }:
let
  common = import ../common.nix { inherit config; };
  inherit (common) cfg ports containers;

  staticConfig = pkgs.writeText "netbird-traefik.yml" (
    builtins.replaceStrings
      [ "@TRAEFIK_WEB_PORT@" "@TRAEFIK_WEBSECURE_PORT@" "@ACME_EMAIL@" ]
      [ (toString ports.traefikWeb) (toString ports.traefikWebsecure) cfg.acmeEmail ]
      (builtins.readFile ./static.yaml)
  );

  dynamicConfig = pkgs.writeText "netbird-traefik-dynamic.yaml" (
    builtins.replaceStrings
      [ "@DOMAIN@" "@SERVER_PORT@" "@PROXY_PORT@" ]
      [ cfg.domain (toString ports.server) (toString ports.proxy) ]
      (builtins.readFile ./dynamic.yaml)
  );
in
{
  virtualisation.quadlet.containers.netbird-traefik = {
    uid = containers.uid;
    containerConfig = {
      Image = cfg.images.traefik;
      AutoUpdate = "registry";
      Pod = "netbird.pod";
      Volume = [
        "${staticConfig}:/etc/traefik/traefik.yml:ro"
        "${dynamicConfig}:/etc/traefik/dynamic.yaml:ro"
        "netbird-letsencrypt.volume:/letsencrypt"
      ];
    };
  };
}
