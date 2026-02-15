{ pkgs, ... }:
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    chromium
  ];

  services.xrdp.enable = true;
  services.xrdp.openFirewall = false;
  services.xrdp.defaultWindowManager = "dbus-run-session startplasma-x11";
}
