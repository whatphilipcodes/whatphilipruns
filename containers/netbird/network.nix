{ config, ... }:
let
  common = import ./common.nix { inherit config; };
  inherit (common) containers ports;
in
{
  virtualisation.quadlet.pods.netbird = {
    uid = containers.uid;
    podConfig = {
      # pasta preserves the client's source address, which STUN needs to report
      # the correct public endpoint.
      Network = "pasta";
      PublishPort = [
        "80:${toString ports.traefikWeb}"
        "443:${toString ports.traefikWebsecure}"
        "${toString ports.stun}:${toString ports.stun}/udp"
      ];
    };
  };
}
