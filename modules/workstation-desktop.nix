{ pkgs, lib, ... }:
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "vscode"
    ];

  environment.systemPackages = with pkgs; [
    chromium
    nodejs_22
    vscode
  ];

  # Keep npm global installs writable on NixOS by defaulting to a user-owned prefix.
  environment.etc."npmrc".text = ''
    prefix=''${HOME}/.local/npm
  '';
  environment.extraInit = ''
    export PATH="$HOME/.local/npm/bin:$PATH"
  '';

  services.xrdp.enable = true;
  services.xrdp.openFirewall = false;
  services.xrdp.defaultWindowManager = "dbus-run-session startplasma-x11";
}
