{ modulesPath, config, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/base.nix
    ../../modules/disko.nix
    ../../modules/users/narkatee.nix
    ../../modules/users/openclaw.nix
    ../../modules/secrets/node.nix
    ../../modules/openclaw-node.nix
    ../../modules/workstation-desktop.nix
  ];

  networking.hostName = "claw-workstation";
  networking.useDHCP = true;
  networking.wireguard.interfaces.wg-openclaw = {
    ips = [ "10.77.0.2/24" ];
    privateKeyFile = config.sops.secrets.wireguard_claw_workstation_private_key.path;
    peers = [
      {
        publicKey = "7HKUx6VntdceF/e85wbPoOcHk7x0ZFIoSYNZSjiofBg=";
        presharedKeyFile = config.sops.secrets.wireguard_openclaw_preshared_key.path;
        allowedIPs = [ "10.77.0.1/32" ];
        endpoint = "46.224.215.114:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  services.openclawNode.gatewayHost = "10.77.0.1";
  services.openclawNode.gatewayPort = 18789;
  users.users.openclaw.hashedPasswordFile = config.sops.secrets.user_openclaw_password.path;

  system.stateVersion = "25.05";
}
