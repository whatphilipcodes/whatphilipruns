{ config, pkgs, ... }:
let
  common = import ./common.nix { inherit config; };
  inherit (common) containers cfg;
in
{
  # A user-defined bridge gives every service an independent network
  # namespace. Quadlet's .network reference also creates a systemd dependency
  # on this network before any of the containers are started.
  virtualisation.quadlet.networks.netbird = {
    uid = containers.uid;
    # This quadlet-nix module writes networkConfig keys verbatim to the
    # Quadlet [Network] section. Quadlet option names are case-sensitive and
    # singular: Driver, Subnet, Label (not driver/subnets/labels).
    networkConfig = {
      Driver = "bridge";
      Subnet = [ cfg.network.subnet ];
      Label = {
        app = "netbird";
      };
    };
  };

  # Rootless Podman's default rootlessport may rewrite source IPs on published
  # UDP ports. NetBird STUN and the reverse-proxy/CrowdSec path need accurate
  # client addresses. The newer pasta/pesto forwarder preserves TCP and UDP
  # source addresses on rootless bridge networks.
  virtualisation.containers = {
    enable = true;
    containersConf.rootless.settings.network.rootless_port_forwarder = "pasta";
  };

  # pesto is shipped by passt. Keep it available to the rootless Podman user.
  environment.systemPackages = [ pkgs.passt ];
}
