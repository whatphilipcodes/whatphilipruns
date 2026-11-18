{ ... }:
let
  secrets = import ../secrets.nix;
in
{
  # ---- users ----
  users.users.philip = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = secrets.SSH_AUTHORIZED_KEYS;
  };
  security.sudo.wheelNeedsPassword = false;

  users.users.podman = {
    isNormalUser = true;
    uid = 1001;
    linger = true;
    openssh.authorizedKeys.keys = secrets.SSH_AUTHORIZED_KEYS;
  };
}
