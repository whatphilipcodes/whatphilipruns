{ config, lib, ... }:
let
  cfg = config.my.pocketId;
  netbird = config.my.netbird;
  proxyDomain = if netbird.proxy.domain == null then "proxy.${netbird.domain}" else netbird.proxy.domain;
  fqdn = "[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+";
  validFqdn = domain: builtins.match fqdn domain != null && builtins.match "[0-9.]+" domain == null;
in
{
  config.assertions = lib.optionals cfg.enable [
    {
      assertion = cfg.domain != null && validFqdn cfg.domain;
      message = "my.pocketId.domain must be a valid public FQDN when my.pocketId.enable = true.";
    }
    {
      assertion = cfg.domain != null && cfg.domain != netbird.domain;
      message = "my.pocketId.domain must not equal the NetBird management hostname.";
    }
    {
      assertion = cfg.domain != null && cfg.domain != proxyDomain;
      message = "my.pocketId.domain must not equal the NetBird reverse-proxy base domain; use a dedicated service hostname such as id.hellmar.de.";
    }
  ];
}
