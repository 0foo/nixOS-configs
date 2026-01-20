# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
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

environment.sessionVariables.LC_TIME = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nick = {
    isNormalUser = true;
    description = "nick";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  virtualisation.docker.enable = true;
 
  services.clamav={
	daemon.enable = true;
        updater.enable = true;
 };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
	parted
	lsof
	git
	vscode
	jetbrains.idea-ultimate
	jetbrains.datagrip
	tree
	openconnect
	spotify
	htop
	google-chrome
	gthumb
	teams-for-linux
  	zoom-us
    	gnome-control-center
    	gnome-terminal
    	nautilus
    	gnome-system-monitor
	ansible
	nettools
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?


  ############################
  services.dbus.enable = true;          # DBus for faster app communication
programs.nix-ld.enable = true;

#  environment.variables.GTK_USE_PORTAL = "0";

#  nix.settings = {
#    max-jobs = "auto";                  # Use all CPU cores for builds
#    cores = 0;
#    download-buffer-size = 536870912;   # 512 MB buffer for faster downloads
#    substituters = [ "https://cache.nixos.org/" ];
#    trusted-public-keys = [ "cache.nixos.org-1:6N9wD0..." ];
#  };

fonts.fontconfig.enable = true;
# fonts.fontconfig.cache.enable = true;
# services.dbus.enable = true;
# services.dbus.packages = [ pkgs.dconf pkgs.gcr pkgs.gnome-keyring ];

services.nscd.enable = true;
services.nscd.config = ''
  enable-cache hosts yes
  positive-time-to-live hosts 3600
  negative-time-to-live hosts 20
'';

powerManagement.cpuFreqGovernor = "performance";

nix.settings.experimental-features = [ "nix-command" "flakes" ];
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

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
}
