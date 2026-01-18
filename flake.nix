{
  description = "nixos flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";

    mkHost = hostName: nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/${hostName}/configuration.nix
        ./hosts/${hostName}/hardware-configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.nick = import ./home/nick.nix;
        }
      ];
    };
  in
  {
    nixosConfigurations = {
      xps13 = mkHost "xps13";

      # Enable these once you add the two required files to each host folder:
      # nuc-desktop = mkHost "nuc-desktop";
      # work-2023-laptop = mkHost "work-2023-laptop";
    };
  };
}
