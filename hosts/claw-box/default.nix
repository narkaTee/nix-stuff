{ modulesPath, config, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/base.nix
    ../../modules/disko.nix
    ../../modules/users/narkatee.nix
    ../../modules/users/openclaw.nix
    ../../modules/secrets/sops.nix
    ../../modules/openclaw.nix
  ];

  networking.hostName = "claw-box";
  networking.useDHCP = true;
  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.wireguard.interfaces.wg-openclaw = {
    ips = [ "10.77.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = config.sops.secrets.wireguard_claw_box_private_key.path;
    peers = [
      {
        publicKey = "SYtTCqzlo4B2J7muu3nOhDuIGxWuo0x2KMfoR0uENkk=";
        presharedKeyFile = config.sops.secrets.wireguard_openclaw_preshared_key.path;
        allowedIPs = [ "10.77.0.2/32" ];
      }
    ];
  };

  users.users.openclaw.hashedPassword = "!";

  system.stateVersion = "25.05";
}
