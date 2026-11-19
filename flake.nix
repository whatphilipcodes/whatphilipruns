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
    {
      nixpkgs,
      disko,
      home-manager,
      quadlet-nix,
      secrets,
      ...
    }:
    {
      nixosConfigurations.wpr = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs.secrets = secrets.lib.secrets;
        modules = [
          disko.nixosModules.disko
          quadlet-nix.nixosModules.default
          (
            { secrets, ... }:
            {
              imports = [ home-manager.nixosModules.home-manager ];
              home-manager.extraSpecialArgs = { inherit secrets; };
            }
          )
          ./modules/base.nix
          ./modules/hetzner.nix
          ./modules/disk.nix
          ./modules/users.nix
          ./modules/ssh.nix
          ./modules/firewall.nix
          ./modules/home.nix

          ./modules/virtualisation.nix
          ./modules/containers
        ];
      };
    };
}
