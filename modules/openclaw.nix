{ config, nix-openclaw, ... }:
{
  nixpkgs.overlays = [ nix-openclaw.overlays.default ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-bak";

  home-manager.users.narkatee = {
    imports = [ nix-openclaw.homeManagerModules.openclaw ];

    home.username = "narkatee";
    home.homeDirectory = "/home/narkatee";
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;
    home.file.".openclaw/openclaw.json".force = true;

    programs.openclaw = {
      enable = true;
      documents = ../openclaw-documents;

      instances.default = {
        enable = true;
        plugins = [ ];
        config = {
          gateway = {
            mode = "local";
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

    systemd.user.services.openclaw-gateway.Service.EnvironmentFile = [
      config.sops.templates.openclaw_gateway_env.path
    ];
  };
}
