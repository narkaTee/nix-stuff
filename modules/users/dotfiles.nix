{ config, lib, pkgs, ... }:
let
  cfg = config.services.dotfilesSync;
  targetDir =
    if cfg.targetDir == null then "/home/${cfg.user}/dotfiles" else cfg.targetDir;
in
{
  options.services.dotfilesSync = {
    enable = lib.mkEnableOption "dotfiles sync + tooling for a user account";

    user = lib.mkOption {
      type = lib.types.str;
      default = "narkatee";
      description = "User account that owns and syncs the dotfiles repository.";
    };

    repository = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/narkaTee/dotfiles";
      description = "Git repository URL for dotfiles.";
    };

    targetDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Target checkout path. Defaults to /home/<user>/dotfiles.";
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" targetDir;
        message = "services.dotfilesSync.targetDir must be an absolute path.";
      }
    ];

    environment.systemPackages = [
      pkgs.ruby
      pkgs.rubyPackages.rake
      pkgs.dash
      pkgs.zsh
      pkgs.vim
      pkgs.neovim
    ];

    systemd.services."dotfiles-sync-${cfg.user}" = {
      description = "Sync dotfiles repository for ${cfg.user}";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ git coreutils ];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";
      };

      script = ''
        set -euo pipefail

        repo_url=${lib.escapeShellArg cfg.repository}
        repo_dir=${lib.escapeShellArg targetDir}

        head_line="$(git ls-remote --symref "$repo_url" HEAD 2>/dev/null | head -n1 || true)"
        case "$head_line" in
          "ref: refs/heads/"*" HEAD")
            default_branch="''${head_line#ref: refs/heads/}"
            default_branch="''${default_branch% HEAD}"
            ;;
          *)
            default_branch="main"
            ;;
        esac

        if [ -d "$repo_dir/.git" ]; then
          git -C "$repo_dir" remote set-url origin "$repo_url"
          git -C "$repo_dir" fetch --prune origin
          git -C "$repo_dir" checkout -B "$default_branch" "origin/$default_branch"
          git -C "$repo_dir" reset --hard "origin/$default_branch"
        elif [ -e "$repo_dir" ]; then
          echo "$repo_dir exists but is not a git repository" >&2
          exit 1
        else
          git clone --depth=1 --branch "$default_branch" "$repo_url" "$repo_dir"
        fi
      '';
    };
  };
}
