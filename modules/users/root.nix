{ secrets, ... }:
{
  imports = [ ../system/home-manager.nix ];

  # ---- home ----
  home-manager.users.root =
    { osConfig, ... }:
    {
      home.stateVersion = osConfig.system.stateVersion;

      programs.git = {
        enable = true;
        settings = {
          user.name = secrets.GH_USERNAME;

          credential.helper = "store";
          credential."https://github.com".username = secrets.GH_USERNAME;
        };
      };
    };
}
