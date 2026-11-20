{ config, ... }:
let
  containers = config.my.containers;
  cfg = config.my.netbird;
in
{
  virtualisation.quadlet.containers.netbird-crowdsec = {
    uid = containers.uid;
    containerConfig = {
      Image = cfg.images.crowdsec;
      AutoUpdate = "registry";
      Network = [ "netbird.network" ];
      NetworkAlias = [ "netbird-crowdsec" ];
      Environment = {
        # Keep the same collection as NetBird's official self-hosted guide.
        # Without mounted log sources it installs the Linux parsers/scenarios,
        # while community blocklist decisions are still available through LAPI.
        COLLECTIONS = "crowdsecurity/linux";
        TZ = "Europe/Berlin";
      };
      Volume = [
        "netbird-crowdsec-config.volume:/etc/crowdsec"
        "netbird-crowdsec-data.volume:/var/lib/crowdsec/data"
      ];
    };
  };
}
