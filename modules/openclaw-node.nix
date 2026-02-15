{ config, lib, nix-openclaw, ... }:
let
  cfg = config.services.openclawNode;
in
{
  options.services.openclawNode = {
    gatewayHost = lib.mkOption {
      type = lib.types.str;
      default = "claw-box";
    };

    gatewayPort = lib.mkOption {
      type = lib.types.port;
      default = 18789;
    };

    nodeDisplayName = lib.mkOption {
      type = lib.types.str;
      default = "node-host";
    };
  };

  config = {
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
        systemd.enable = false;

        instances.default = {
          enable = true;
          plugins = [ ];
        };

        config = {
          gateway = {
            mode = "remote";
            remote = {
              url = "ws://${cfg.gatewayHost}:${toString cfg.gatewayPort}";
              transport = "direct";
            };
          };
        };
      };

      home.file.".openclaw/openclaw.json".enable = false;
      home.activation.openclawConfigFiles = lib.mkForce { before = [ ]; after = [ ]; data = ""; };

      systemd.user.services.openclaw-node-host = {
        Unit = {
          Description = "OpenClaw node host";
          X-Restart-Triggers = [ config.sops.secrets.openclaw_gateway_token.sopsFileHash ];
        };
        Service = {
          ExecStart = "/etc/profiles/per-user/openclaw/bin/openclaw node run --host ${cfg.gatewayHost} --port ${toString cfg.gatewayPort} --display-name ${cfg.nodeDisplayName}";
          Restart = "always";
          RestartSec = "2s";
          EnvironmentFile = [ config.sops.templates.openclaw_node_env.path ];
          Environment = [
            "PATH=/etc/profiles/per-user/openclaw/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
          ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      systemd.user.startServices = "sd-switch";
    };

    services.openclawNode.nodeDisplayName = lib.mkDefault config.networking.hostName;
  };
}
