{
  # ---- disk (Hetzner Cloud ARM: UEFI only) ----
  #
  # Partitions get an explicit `device` (the kernel's node) instead of disko's default
  # /dev/disk/by-partlabel/<label>. In the nixos-anywhere installer on Hetzner those udev
  # symlinks show up a moment AFTER disko's `mkfs` runs ("mkfs.vfat: unable to open
  # /dev/disk/by-partlabel/disk-main-ESP"), while /dev/sdaN exists as soon as the kernel
  # has scanned the table. The numbers follow the order of the partitions below.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          device = "/dev/sda1";
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          device = "/dev/sda2";
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
