{ ... }:
{
  # ---- firewall (replaces ufw) ----
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      3478 # netbird STUN
      51820 # netbird WIREGUARD
    ];
  };
}
