{ config, ... }:
{
  sops.defaultSopsFile = ../../secrets/claw-workstation.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.openclaw_gateway_token = {
    sopsFile = ../../secrets/claw-shared.yaml;
    owner = "openclaw";
    group = "openclaw";
    mode = "0400";
  };

  sops.secrets.user_openclaw_password = {
    sopsFile = ../../secrets/claw-workstation.yaml;
    neededForUsers = true;
    mode = "0400";
  };

  sops.secrets.wireguard_claw_workstation_private_key = {
    mode = "0400";
  };

  sops.secrets.wireguard_openclaw_preshared_key = {
    sopsFile = ../../secrets/claw-shared.yaml;
    mode = "0400";
  };

  sops.templates.openclaw_node_env = {
    owner = "openclaw";
    group = "openclaw";
    mode = "0400";
    content = ''
      OPENCLAW_GATEWAY_TOKEN=${config.sops.placeholder.openclaw_gateway_token}
    '';
  };
}
