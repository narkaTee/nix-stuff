{ ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  time.timeZone = "Europe/Berlin";
  console.keyMap = "de";

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  services.openssh.settings.PermitRootLogin = "no";
  services.sshguard.enable = true;
  services.sshguard.services = [ "sshd" ];

  networking.firewall.enable = true;
  networking.firewall.allowPing = false;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ ];

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.root.openssh.authorizedKeys.keys = [ ];

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "/dev/sda";
}
