{ config, lib, pkgs, ... }:
let
  podman = "${config.virtualisation.quadlet.podman}/bin/podman";
  createEncryptionSecret = pkgs.writeShellScript "pocket-id-create-encryption-secret" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.openssl ]}:$PATH
    podman=${lib.escapeShellArg podman}
    secretName="pocket-id-encryption-key"

    if "$podman" secret inspect "$secretName" >/dev/null 2>&1; then
      echo "Podman secret '$secretName' already exists; preserving it." >&2
      exit 0
    fi

    # Pocket ID requires a stable encryption key (at least 16 bytes). Generate
    # it once and pass it directly to Podman; never create a plaintext file.
    openssl rand -base64 32 | tr -d '\n' | "$podman" secret create "$secretName" - >/dev/null
    echo "Created Podman secret '$secretName'." >&2
  '';
in
{
  config = lib.mkIf config.my.pocketId.enable {
    virtualisation.quadlet.containers.pocket-id.serviceConfig.ExecStartPre = "${createEncryptionSecret}";
  };
}
