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
    vscode
  ];

  services.xrdp.enable = true;
  services.xrdp.openFirewall = false;
  services.xrdp.defaultWindowManager = "dbus-run-session startplasma-x11";
}
