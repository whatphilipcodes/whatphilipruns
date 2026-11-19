{
  # ---- ssh hardening ----
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      MaxAuthTries = 3;
      AllowTcpForwarding = "yes";
      X11Forwarding = false;
      AllowAgentForwarding = "no";
      AllowUsers = [
        "philip"
        "podman"
      ];
    };
  };
  services.fail2ban.enable = true;
}
