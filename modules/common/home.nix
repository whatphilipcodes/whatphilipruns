{ secrets, ... }:
{
  home-manager.users.philip = {
    home.stateVersion = "26.05";

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
  home-manager.users.root = {
    home.stateVersion = "26.05";

    programs.git = {
      enable = true;
      settings = {
        credential.helper = "store";
      };
    };
  };
}
