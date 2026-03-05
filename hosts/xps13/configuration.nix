{ config, pkgs, ... }:

{
  imports = [
    ../common/shared.nix
  ];

  boot.loader.timeout = 0;
  boot.loader.systemd-boot.configurationLimit = 5;

  boot.initrd.luks.devices."luks-3c9cb9b5-c350-42ed-866d-c452ebe0763a".device =
    "/dev/disk/by-uuid/3c9cb9b5-c350-42ed-866d-c452ebe0763a";
  boot.kernelModules = [ "tun" ];

  networking.hostName = "xps13";

  users.users.nick.packages = with pkgs; [ ];

  environment.systemPackages = with pkgs; [
    xwayland
    xwayland-run
    openconnect
    gpclient
    gp-saml-gui
    gpauth
    transmission_4-gtk
    net-tools
  ];

  services.transmission.enable = true;
  services.gnome.gnome-software.enable = false;

  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };

  services.syncthing = {
    enable = true;
    user = "nick";
    group = "users";
    dataDir = "/home/nick/syncthing";
    configDir = "/home/nick/.config/syncthing";
    openDefaultPorts = true;
    guiAddress = "127.0.0.1:8384";
  };
}
