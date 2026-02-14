{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/base.nix
    ../../modules/disko.nix
    ../../modules/users/narkatee.nix
  ];

  networking.hostName = "claw-box";
  networking.useDHCP = true;

  system.stateVersion = "25.05";
}
