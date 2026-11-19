{ secrets, ... }:
{
  users.users.podman = {
    isNormalUser = true;
    uid = 1001;
    openssh.authorizedKeys.keys = secrets.SSH_AUTHORIZED_KEYS;
  };
}
