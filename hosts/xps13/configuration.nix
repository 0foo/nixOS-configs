{ config, pkgs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;
  boot.loader.systemd-boot.configurationLimit = 5;

  boot.initrd.luks.devices."luks-3c9cb9b5-c350-42ed-866d-c452ebe0763a".device =
    "/dev/disk/by-uuid/3c9cb9b5-c350-42ed-866d-c452ebe0763a";

  networking.hostName = "xps13";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.nick = {
    isNormalUser = true;
    description = "nick";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [ ];
  };

  programs.firefox.enable = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    tree
    xwayland
    xwayland-run
    openconnect
    gpclient
    gp-saml-gui
    gpauth
    tcpdump
    rclone
    ansible
    home-manager
    transmission_4-gtk
    net-tools
  ];

  services.transmission.enable = true;

  system.stateVersion = "25.11";

  virtualisation.docker.enable = true;
  boot.kernelModules = [ "tun" ];
  services.gnome.gnome-software.enable = false;

  # With flakes, prefer setting these at the Nix daemon level:
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };
  
  services.tailscale.enable = true;

services.syncthing = {
  enable = true;

  user = "nick";
  group = "users";

  dataDir = "/home/nick/syncthing";
  configDir = "/home/nick/.config/syncthing";

  openDefaultPorts = true;

  # set GUI bind without triggering the merge helper
  guiAddress = "127.0.0.1:8384";
};

}
