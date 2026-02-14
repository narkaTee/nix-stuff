{
  description = "Hetzner Cloud bootstrap with nixos-anywhere";

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

  outputs = { nixpkgs, disko, home-manager, sops-nix, nix-openclaw, ... }: {
    nixosConfigurations.claw-box = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        ./hosts/claw-box/default.nix
        ./modules/secrets/sops.nix
        ./modules/openclaw.nix
      ];
      specialArgs = {
        inherit home-manager nix-openclaw;
      };
    };
  };
}
