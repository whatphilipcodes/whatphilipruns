{ config, lib, ... }:
{
  # ---- ssh hardening ----
  services.openssh = {
    enable = true;
    ports = lib.mkDefault [ 2222 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      MaxAuthTries = 3;
      AllowTcpForwarding = "yes";
      X11Forwarding = false;
      AllowAgentForwarding = "no";
      AllowUsers = lib.attrNames (lib.filterAttrs (_: user: user.isNormalUser) config.users.users);
    };
  };
}
