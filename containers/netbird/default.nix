{ ... }:
{
  imports = [
    # Keep using the same quadlet-nix implementation as the original module.
    ../../modules/virtualisation/quadlet.nix

    ./options.nix
    ./assertions.nix
    ./network.nix
    ./volumes.nix
    ./podman-secrets.nix
    ./crowdsec
    ../traefik
    ./dashboard.nix
    ./server
    ./proxy
  ];
}
