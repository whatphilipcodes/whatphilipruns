{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.containers;
in
{
  imports = [ inputs.quadlet-nix.nixosModules.default ];

  options.my.containers = {
    owner = lib.mkOption {
      type = lib.types.str;
      example = "podman";
      description = ''
        User whose systemd user manager runs the rootless containers of this
        host. The user must be defined with a fixed uid.
      '';
    };

    uid = lib.mkOption {
      type = lib.types.ints.u32;
      readOnly = true;
      default = config.users.users.${cfg.owner}.uid;
      description = "uid of the owner; container files pass it as `uid`.";
    };
  };

  config = {
    virtualisation.quadlet.enable = true;

    users.users.${cfg.owner} = {
      linger = lib.mkDefault true;
      autoSubUidGidRange = lib.mkDefault true;
    };

    boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;
  };
}
