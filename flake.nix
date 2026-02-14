{
  description = "Hetzner Cloud bootstrap with nixos-anywhere";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
  };

  outputs = { nixpkgs, disko, ... }: {
    nixosConfigurations.claw-box = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hosts/claw-box/default.nix
      ];
    };
  };
}
