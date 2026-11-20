{ config, lib, ... }:
let
  cfg = config.my.pocketId;
  containers = config.my.containers;
in
{
  imports = [
    ./options.nix
    ./assertions.nix
    ./secrets.nix
  ];

  config = lib.mkIf cfg.enable {
    virtualisation.quadlet.volumes.pocket-id-data = {
      uid = containers.uid;
      volumeConfig.Label = {
        app = "pocket-id";
      };
    };

    virtualisation.quadlet.containers.pocket-id = {
      uid = containers.uid;
      containerConfig = {
        Image = cfg.image;
        AutoUpdate = "registry";
        # Pocket ID has its own network namespace and is reachable only by
        # other containers on the dedicated NetBird bridge network.
        Network = [ "netbird.network" ];
        NetworkAlias = [ "pocket-id" ];
        Environment = {
          APP_URL = "https://${cfg.domain}";
          ENCRYPTION_KEY_FILE = "/run/secrets/pocket-id-encryption-key";
          HOST = "0.0.0.0";
          PORT = "1411";
          PUID = "1000";
          PGID = "1000";
          # Traefik connects from the dedicated bridge subnet and forwards the
          # original client address in X-Forwarded-For.
          TRUST_PROXY = config.my.netbird.network.subnet;
          ALLOW_INSECURE_CALLBACK_URLS = "false";
        };
        Volume = [
          "pocket-id-data.volume:/app/data"
        ];
        Secret = [
          "pocket-id-encryption-key,type=mount,target=/run/secrets/pocket-id-encryption-key,uid=1000,gid=1000,mode=0400"
        ];
        HealthCmd = "/app/pocket-id healthcheck";
        HealthInterval = "1m30s";
        HealthTimeout = "5s";
        HealthRetries = 2;
        HealthStartPeriod = "10s";
      };
      unitConfig = {
        Wants = [ "netbird-traefik.service" ];
        After = [ "netbird-traefik.service" ];
      };
    };
  };
}
