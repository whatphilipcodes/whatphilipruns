{ config, lib, ... }:
let
  cfg = config.my.netbird;
  common = import ./common.nix { inherit config; };
  proxyDomain = common.proxyDomain;

  fqdn = "[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+";
  traefikTag = builtins.match ".*:v?([0-9]+(\\.[0-9]+)*)" cfg.images.traefik;
  validFqdn = domain:
    builtins.match fqdn domain != null
    && builtins.match "[0-9.]+" domain == null;
in
{
  config.assertions = [
    {
      assertion = validFqdn cfg.domain && cfg.domain != "netbird.example.com";
      message = "my.netbird.domain must be a real FQDN such as netbird.my-domain.com, not an IP address or netbird.example.com.";
    }
    {
      assertion = validFqdn proxyDomain;
      message = "my.netbird.proxy.domain (or its default proxy.<my.netbird.domain>) must be a valid FQDN.";
    }
    {
      assertion =
        !(lib.hasInfix "@" cfg.images.traefik)
        && traefikTag != null
        && lib.versionAtLeast (builtins.head traefikTag) "3.7.13";
      message = "my.netbird.images.traefik must be a numeric Traefik tag of v3.7.13 or newer without a digest.";
    }
  ];
}
