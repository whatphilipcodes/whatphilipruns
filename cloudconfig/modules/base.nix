{ pkgs, ... }:
{
  config = {
    # ---- base ----
    networking.hostName = "wpr";

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    system.stateVersion = "26.05";

    environment.systemPackages = with pkgs; [
      ghostty.terminfo
      git
      curl
      gettext
      pwgen
      btop
    ];
  };
}
