{ ... }:
{
  imports = [
    # This path is one level deeper than the original containers/netbird.nix.
    ../../modules/virtualisation/quadlet.nix

    ./options.nix
    ./assertions.nix
    ./network.nix
    ./volumes.nix
    ./podman-secrets.nix
    ./traefik
    ./dashboard.nix
    ./server
  ];
}
