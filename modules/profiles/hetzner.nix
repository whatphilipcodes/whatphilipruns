{
  config,
  lib,
  modulesPath,
  ...
}:
{
  # Virtio drivers (disk, network, RNG, ...) in the initrd, so the VM can find its root disk and network. Shipped with nixpkgs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/qemu-guest.nix (The NixOS wiki recommends having this imported on Hetzner Cloud; importing it again if hardware-configuration.nix already does so is harmless.)
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  options.my.hetzner.ipv6Address = lib.mkOption {
    type = lib.types.str;
    example = "2a01:4f8:c012:abcd::1";
    description = ''
      The server's IPv6 address, without prefix length. Use ::1 of the /64
      shown under Networking in the Hetzner Console.
    '';
  };

  config = {
    # ── Virtualization ─────────────────────────────────────────────────────────
    # Hetzner Cloud servers are QEMU/KVM guests.

    # QEMU guest agent: lets the hypervisor talk to the running system. Hetzner's "Reset root password" action in the Console relies on it (https://hcloud-python.readthedocs.io/en/stable/_modules/hcloud/servers/client.html). The Hetzner Console cannot reset the root password without it.
    services.qemuGuest.enable = true;

    # ── Boot & console ─────────────────────────────────────────────────────────
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = false;

    # Hetzner ARM (CAX): without these two lines the screen goes blank after the bootloader. The virtio GPU is loaded early in the initrd and the kernel console is directed to the screen shown in the Hetzner web console. Source: https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Cloud
    boot.initrd.kernelModules = [ "virtio_gpu" ];
    boot.kernelParams = [ "console=tty" ];

    # ── Networking ─────────────────────────────────────────────────────────────
    # Mirrors the configuration Hetzner's tooling (cloud-init) generates on its own images, as documented here: https://docs.hetzner.com/de/cloud/servers/primary-ips/primary-ip-configuration/

    # IPv4: DHCP
    # IPv6: static address from the server's /64 (use <prefix>::1), with the fixed link-local gateway fe80::1. Hetzner's examples configure this statically and switch IPv6 autoconfiguration off.
    # DNS:  Hetzner's resolvers

    networking.useDHCP = false; # no implicit DHCP on all interfaces
    networking.useNetworkd = true; # use systemd-networkd as the backend
    systemd.network.enable = true;

    networking.nameservers = [
      "185.12.64.1"
      "185.12.64.2"
      "2a01:4ff:ff00::add:1"
      "2a01:4ff:ff00::add:2"
    ];

    systemd.network.networks."30-wan" = {
      # Match the Ethernet interface by name (en*, e.g. enp1s0) rather than by MAC.
      matchConfig.Name = "en*";
      networkConfig.DHCP = "ipv4";
      # The /64 shown under Networking in the Hetzner Console; the server uses ::1.
      address = [ "${config.my.hetzner.ipv6Address}/64" ];
      routes = [ { Gateway = "fe80::1"; } ];
    };
  };
}
