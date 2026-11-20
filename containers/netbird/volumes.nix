{ config, ... }:
let
  containers = config.my.containers;
  volume = {
    uid = containers.uid;
    volumeConfig.Label = {
      app = "netbird";
    };
  };
in
{
  virtualisation.quadlet.volumes = {
    netbird-data = volume;
    netbird-letsencrypt = volume;
    netbird-proxy-certs = volume;
    netbird-crowdsec-config = volume;
    netbird-crowdsec-data = volume;
  };
}
