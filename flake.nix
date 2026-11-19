{
  description = "whatphilipruns";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quadlet-nix = {
      url = "github:mirkolenz/quadlet-nix";
    };

    secrets = {
      url = "git+https://github.com/whatphilipcodes/inix-secrets";
    };
  };

  outputs =
    inputs@{ nixpkgs, secrets, ... }:
    let
      lib = nixpkgs.lib;
      hostNames = lib.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );

      mkHost =
        name:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            secrets = secrets.lib.secrets;
          };
          modules = [
            { networking.hostName = name; }
            ./hosts/${name}
          ];
        };
    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost;
    };
}
