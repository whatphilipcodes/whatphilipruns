{ config, lib, pkgs, ... }:
let
  podman = "${config.virtualisation.quadlet.podman}/bin/podman";

  # Secrets are created directly from stdin in the rootless Podman store.
  # They are generated only when missing; never rotate them on service restart.
  createSecrets = pkgs.writeShellScript "netbird-create-podman-secrets" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.openssl ]}:$PATH

    podman=${lib.escapeShellArg podman}

    create_secret() {
      name="$1"
      encoding="$2"

      if "$podman" secret inspect "$name" >/dev/null 2>&1; then
        echo "Podman secret '$name' already exists; preserving it." >&2
        return 0
      fi

      case "$encoding" in
        base64-unpadded)
          # Keep the format used by the original NetBird setup script for authSecret.
          openssl rand -base64 32 | tr -d '=\n' | "$podman" secret create "$name" - >/dev/null
          ;;
        base64)
          # Preserve base64 padding for the encryption and cookie keys.
          openssl rand -base64 32 | tr -d '\n' | "$podman" secret create "$name" - >/dev/null
          ;;
        *)
          echo "Unknown secret encoding: $encoding" >&2
          exit 1
          ;;
      esac

      echo "Created Podman secret '$name'." >&2
    }

    create_secret netbird-auth-secret base64-unpadded
    create_secret netbird-store-encryption-key base64
    create_secret netbird-session-cookie-key base64
  '';
in
{
  # ExecStartPre runs as the same rootless user and against the same Podman
  # store as the Quadlet container. This runs before Podman creates the container,
  # so the Secret= entries in server/default.nix can resolve.
  virtualisation.quadlet.containers.netbird-server.serviceConfig.ExecStartPre = "${createSecrets}";
}
