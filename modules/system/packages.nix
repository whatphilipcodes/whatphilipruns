{ pkgs, ... }:
{
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
}
