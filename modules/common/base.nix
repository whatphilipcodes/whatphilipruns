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

    programs.nix-ld.enable = true; # fixes vscode-server issue
    environment.systemPackages = with pkgs; [
      ghostty.terminfo
      nixd
      nixfmt
      git
      curl
      gettext
      pwgen
      btop
    ];
  };
}
