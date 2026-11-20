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
    # Traefik and the NetBird proxy share a pod network namespace. The proxy
    # listens on 8443, so Traefik's HTTPS entrypoint must use another port.
    traefikWebsecure = 8444;
    proxy = 8443;
    stun = 3478;
    proxyWireguard = cfg.proxy.wireguardPort;
  };
}
