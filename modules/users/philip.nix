{ secrets, ... }:
{
  imports = [ ../system/home-manager.nix ];

  # ---- user ----
  users.users.philip = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = secrets.SSH_AUTHORIZED_KEYS;
  };
  security.sudo.wheelNeedsPassword = false;

  # ---- home ----
  home-manager.users.philip =
    { osConfig, ... }:
    {
      home.stateVersion = osConfig.system.stateVersion;

      programs.git = {
        enable = true;
        settings = {
          init.defaultBranch = "main";
          pull.rebase = true;

          user.name = secrets.GH_USERNAME;
          user.email = secrets.EMAIL;

          credential.helper = "store";
          credential."https://github.com".username = secrets.GH_USERNAME;
        };
      };
    };
}
