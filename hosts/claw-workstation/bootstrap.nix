{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/base.nix
    ../../modules/disko.nix
    ../../modules/users/narkatee.nix
    ../../modules/workstation-desktop.nix
  ];

  networking.hostName = "claw-workstation";
  networking.useDHCP = true;

  system.stateVersion = "25.05";
}
