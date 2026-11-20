{ lib, ... }:
{
  options.my.pocketId = {
    enable = lib.mkEnableOption "Pocket ID OIDC identity provider";

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "id.hellmar.de";
      description = "Public HTTPS hostname used for Pocket ID and its WebAuthn/passkey origin.";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/pocket-id/pocket-id:v2";
      description = "Pocket ID container image. The v2 tag tracks stable v2 releases.";
    };
  };
}
