{ config, lib, nix-openclaw, ... }:
{
  nixpkgs.overlays = [ nix-openclaw.overlays.default ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-bak";

  home-manager.users.openclaw = {
    imports = [ nix-openclaw.homeManagerModules.openclaw ];

    home.username = "openclaw";
    home.homeDirectory = "/home/openclaw";
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;

    programs.openclaw = {
      enable = true;

      instances.default = {
        enable = true;
        plugins = [ ];
        config = {
          gateway = {
            mode = "local";
            bind = "lan";
            auth = {
              mode = "token";
            };
          };

          channels.telegram = {
            tokenFile = config.sops.secrets.openclaw_telegram_token.path;
            dmPolicy = "pairing";
            groups = {
              "*" = { requireMention = true; };
            };
          };
        };
      };
    };

    home.file.".openclaw/openclaw.json".enable = false;
    home.activation.openclawConfigFiles = lib.mkForce { before = [ ]; after = [ ]; data = ""; };

    systemd.user.services.openclaw-gateway.Service.EnvironmentFile = [
      config.sops.templates.openclaw_gateway_env.path
    ];
    systemd.user.services.openclaw-gateway.Service.Environment = [
      "PATH=/etc/profiles/per-user/openclaw/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ];
    systemd.user.services.openclaw-gateway.Unit.X-Restart-Triggers = [
      config.sops.secrets.openclaw_gateway_token.sopsFileHash
    ];
    systemd.user.services.openclaw-gateway.Install = {
      WantedBy = [ "default.target" ];
    };
    systemd.user.startServices = "sd-switch";
  };

  networking.firewall.interfaces.wg-openclaw.allowedTCPPorts = [ 18789 ];
}
