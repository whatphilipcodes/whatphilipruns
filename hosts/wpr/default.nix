{ secrets, ... }:
{
  imports = [
    # ---- platform & hardware ----
    ./disk.nix
    ../../modules/profiles/hetzner.nix

    # ---- system ----
    ../../modules/system/nix.nix
    ../../modules/system/nix-ld.nix
    ../../modules/system/packages.nix

    # ---- services ----
    ../../modules/services/ssh.nix
    ../../modules/services/fail2ban.nix
    ./firewall.nix

    # ---- users (each one brings its own home-manager settings) ----
    ../../modules/users/philip.nix
    ../../modules/users/podman.nix
    ../../modules/users/root.nix

    # ---- containers (these pull in modules/virtualisation/quadlet.nix) ----
    ../../containers/netbird
  ];

  # ---- host identity ----
  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "26.05";

  # ---- host-specific values for the imported modules ----
  my.hetzner.ipv6Address = secrets.HETZNER_WPR_IPV6_ADDRESS;
  my.containers.owner = "podman";

  # ---- netbird ----
  my.netbird = {
    domain = "vpn.hellmar.de";
    proxy.domain = "hellmar.de";
    acmeEmail = secrets.EMAIL;
  };
}
