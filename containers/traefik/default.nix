{ config, lib, pkgs, ... }:
let
  common = import ../netbird/common.nix { inherit config; };
  inherit (common) cfg ports containers;
  pocketCfg = config.my.pocketId;
  pocketDomain = if pocketCfg.enable && pocketCfg.domain != null then pocketCfg.domain else "pocket-id-disabled.invalid";

  staticConfig = pkgs.writeText "traefik.yml" (
    builtins.replaceStrings
      [ "@TRAEFIK_WEB_PORT@" "@TRAEFIK_WEBSECURE_PORT@" "@ACME_EMAIL@" ]
      [ (toString ports.traefikWeb) (toString ports.traefikWebsecure) cfg.acmeEmail ]
      (builtins.readFile ./static.yaml)
  );

  netbirdDynamicConfig = pkgs.writeText "traefik-netbird.yaml" (
    builtins.replaceStrings
      [ "@DOMAIN@" "@SERVER_PORT@" "@PROXY_PORT@" "@POCKET_ID_DOMAIN@" ]
      [ cfg.domain (toString ports.server) (toString ports.proxy) pocketDomain ]
      (builtins.readFile ./dynamic.yaml)
  );

  pocketIdDynamicConfig = pkgs.writeText "traefik-pocket-id.yaml" (
    builtins.replaceStrings
      [ "@POCKET_ID_DOMAIN@" ]
      [ pocketCfg.domain ]
      (builtins.readFile ../pocket-id/traefik.yaml)
  );
in
{
  imports = [ ../pocket-id/options.nix ];

  virtualisation.quadlet.containers.netbird-traefik = {
    uid = containers.uid;
    containerConfig = {
      Image = cfg.images.traefik;
      AutoUpdate = "registry";
      Network = [ "netbird.network" ];
      NetworkAlias = [ "traefik" ]
        ++ lib.optional (pocketCfg.enable && pocketCfg.domain != null) pocketCfg.domain;
      PublishPort = [
        "80:${toString ports.traefikWeb}"
        "443:${toString ports.traefikWebsecure}"
      ];
      Volume = [
        "${staticConfig}:/etc/traefik/traefik.yml:ro"
        "${netbirdDynamicConfig}:/etc/traefik/dynamic/netbird.yaml:ro"
        "netbird-letsencrypt.volume:/letsencrypt"
      ] ++ lib.optional pocketCfg.enable
        "${pocketIdDynamicConfig}:/etc/traefik/dynamic/pocket-id.yaml:ro";
    };
  };
}
