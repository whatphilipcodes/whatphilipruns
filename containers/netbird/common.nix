{ config }:
{
  cfg = config.my.netbird;
  containers = config.my.containers;

  ports = {
    server = 8081;
    traefikWeb = 8000;
    traefikWebsecure = 8443;
    stun = 3478;
  };
}
