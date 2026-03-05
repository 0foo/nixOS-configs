{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/shared.nix
  ];

  networking.hostName = "nixos";
  networking.firewall.checkReversePath = "loose";

  services.resolved.enable = true;
  networking.useHostResolvConf = false;
  networking.networkmanager.dns = "systemd-resolved";

  environment.sessionVariables.LC_TIME = "en_US.UTF-8";

  security.sudo.wheelNeedsPassword = false;

  users.users.nick = {
    extraGroups = [ "libvirtd" "kvm" ];
    packages = with pkgs; [ ];
  };

  virtualisation.docker = {
    daemon.settings = {
      bip = "10.200.0.1/24";
      "insecure-registries" = [ "nuc-desktop:5000" ];
      default-address-pools = [
        {
          base = "10.201.0.0/16";
          size = 24;
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    parted
    lsof
    vscode
    jetbrains.idea-ultimate
    jetbrains.datagrip
    openconnect
    spotify
    htop
    gthumb
    teams-for-linux
    zoom-us
    gnome-control-center
    gnome-terminal
    nautilus
    gnome-system-monitor
    nettools
    transmission_4-gtk
    virt-manager
    virt-viewer
    openconnect_openssl
    gpclient
    pay-respects
    (pkgs.writeShellScriptBin "vpn-on" (builtins.readFile ./files/openconnect/vpn-on))
    (pkgs.writeShellScriptBin "vpn-off" (builtins.readFile ./files/openconnect/vpn-off))
    sqlcmd
    google-chrome
    pgloader
    freetds
  ];

  services.transmission.enable = true;

  programs.bash.interactiveShellInit = ''
    eval "$(pay-respects bash)"
    alias fuck='pay-respects'
  '';

  services.dbus.enable = true;
  programs.nix-ld.enable = true;

  fonts.fontconfig.enable = true;

  services.nscd.enable = true;
  services.nscd.config = ''
    enable-cache hosts yes
    positive-time-to-live hosts 3600
    negative-time-to-live hosts 20
  '';

  powerManagement.cpuFreqGovernor = "performance";

  programs.dconf.enable = true;

  system.activationScripts.gnomeClock12h.text = ''
    /run/current-system/sw/bin/gsettings set org.gnome.desktop.interface clock-format '12h' || true
  '';

  systemd.user.services.gnome-12h-clock = {
    description = "Force GNOME clock to 12-hour format";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/gsettings set org.gnome.desktop.interface clock-format '12h'";
    };
  };

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  environment.etc."openconnect/hipreport.sh" = {
    source = ./files/openconnect/hipreport.sh;
    mode = "0755";
  };

  environment.etc."openconnect/vpn-on" = {
    source = ./files/openconnect/vpn-on;
    mode = "0755";
  };

  environment.etc."openconnect/vpn-off" = {
    source = ./files/openconnect/vpn-off;
    mode = "0755";
  };

  services.avahi.enable = false;

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
