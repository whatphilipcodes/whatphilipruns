{ ... }:
{
  # ---- firewall (replaces ufw) ----
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      443
    ];
  };
}
