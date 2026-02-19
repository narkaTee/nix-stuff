{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/base.nix
    ../../modules/disko.nix
    ../../modules/users/narkatee.nix
    ../../modules/users/dotfiles.nix
    ../../modules/workstation-desktop.nix
  ];

  networking.hostName = "claw-workstation";
  networking.useDHCP = true;
  services.dotfilesSync = {
    enable = true;
    user = "narkatee";
    repository = "https://github.com/narkaTee/dotfiles";
  };

  system.stateVersion = "25.05";
}
