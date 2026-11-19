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
  };
}
