{ config, ... }:
{
  sops.defaultSopsFile = ../../secrets/claw-box.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.openclaw_telegram_token = {
    owner = "openclaw";
    group = "openclaw";
    mode = "0400";
  };

  sops.secrets.openclaw_gateway_token = {
    owner = "openclaw";
    group = "openclaw";
    mode = "0400";
  };

  sops.secrets.openclaw_anthropic_api_key = {
    owner = "openclaw";
    group = "openclaw";
    mode = "0400";
  };

  sops.secrets.openclaw_brave_search_token = {
    owner = "openclaw";
    group = "openclaw";
    mode = "0400";
  };

  sops.templates.openclaw_gateway_env = {
    owner = "openclaw";
    group = "openclaw";
    mode = "0400";
    content = ''
      OPENCLAW_GATEWAY_TOKEN=${config.sops.placeholder.openclaw_gateway_token}
      ANTHROPIC_API_KEY=${config.sops.placeholder.openclaw_anthropic_api_key}
      BRAVE_API_KEY=${config.sops.placeholder.openclaw_brave_search_token}
    '';
  };
}
