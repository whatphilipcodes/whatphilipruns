{ config, lib, ... }:
let
  cfg = config.my.netbird;

  fqdn = "[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+";
  traefikTag = builtins.match ".*:v?([0-9]+(\\.[0-9]+)*)" cfg.images.traefik;
in
{
  config.assertions = [
    {
      assertion =
        builtins.match fqdn cfg.domain != null
        && builtins.match "[0-9.]+" cfg.domain == null
        && cfg.domain != "netbird.example.com";
      message = "my.netbird.domain must be a real FQDN such as netbird.my-domain.com, not an IP address or netbird.example.com.";
    }
    {
      assertion =
        !(lib.hasInfix "@" cfg.images.traefik)
        && traefikTag != null
        && lib.versionAtLeast (builtins.head traefikTag) "3.7.13";
      message = "my.netbird.images.traefik must be a numeric Traefik tag of v3.7.13 or newer without a digest (needed for aliasHeadersStrategy and its header-sanitization fix).";
    }
  ];
}
