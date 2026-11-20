{ config, ... }:
let
  common = import ./common.nix { inherit config; };
  inherit (common) containers cfg ports;
in
{
  virtualisation.quadlet.pods.netbird = {
    uid = containers.uid;
    podConfig = {
      # pasta keeps the host's source-address behavior while all containers in
      # this pod share one network namespace and can reach each other on loopback.
      Network = "pasta";
      PublishPort = [
        "80:${toString ports.traefikWeb}"
        "443:${toString ports.traefikWebsecure}"
        "${toString ports.stun}:${toString ports.stun}/udp"
        "${toString ports.proxyWireguard}:${toString ports.proxyWireguard}/udp"
      ] ++ cfg.proxy.additionalPublishPorts;
    };
  };
}
