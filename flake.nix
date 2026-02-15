{
  description = "Welcome to the land of the nix-lobster";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-openclaw.url = "github:openclaw/nix-openclaw";
    nix-openclaw.inputs.nixpkgs.follows = "nixpkgs";
    nix-openclaw.inputs.home-manager.follows = "home-manager";
  };

  outputs = { nixpkgs, disko, home-manager, sops-nix, nix-openclaw, ... }:
    let
      mkHost = hostPath: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          hostPath
        ];
        specialArgs = {
          inherit home-manager nix-openclaw;
        };
      };
    in
    {
      nixosConfigurations.claw-box = mkHost ./hosts/claw-box/default.nix;
      nixosConfigurations.claw-workstation-bootstrap = mkHost ./hosts/claw-workstation/bootstrap.nix;
      nixosConfigurations.claw-workstation = mkHost ./hosts/claw-workstation/default.nix;
    };
}
