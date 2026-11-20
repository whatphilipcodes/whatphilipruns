{ config }:
let
  cfg = config.my.netbird;
in
{
  inherit cfg;
  containers = config.my.containers;

  proxyDomain =
    if cfg.proxy.domain == null then "proxy.${cfg.domain}" else cfg.proxy.domain;

  ports = {
    server = 8081;
    traefikWeb = 8000;
    # Traefik has its own network namespace, so it can use the standard HTTPS
    # port independently of the NetBird proxy's internal listener.
    traefikWebsecure = 443;
    proxy = 8443;
    stun = 3478;
    proxyWireguard = cfg.proxy.wireguardPort;
  };
}
