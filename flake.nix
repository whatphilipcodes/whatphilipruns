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
  };

  outputs =
    {
      nixpkgs,
      disko,
      home-manager,
      quadlet-nix,
      ...
    }:
    {
      nixosConfigurations.whatphilipruns = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          quadlet-nix.nixosModules.quadlet
          ./modules/base.nix
          ./modules/hetzner.nix
          ./modules/disk.nix
          ./modules/users.nix
          ./modules/ssh.nix
          ./modules/firewall.nix
          ./modules/home.nix
        ];
      };
    };
}
