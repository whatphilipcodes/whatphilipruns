{ inputs, secrets, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.extraSpecialArgs = { inherit secrets; };
}
