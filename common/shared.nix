{ config, pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  programs.nix-ld.enable = true;

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
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

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
  };

  programs.firefox.enable = false;

  nixpkgs.config.allowUnfree = true;


  environment.systemPackages = with pkgs; [
    git
    tree
    tcpdump
    rclone
    ansible
    home-manager
    gemini-cli
    gnomeExtensions.workspace-matrix
    docker-compose
  ];

  virtualisation.docker.enable = true;
  services.tailscale.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "26.05";


  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        # Tell GNOME Shell to turn the extension ON
        "org/gnome/shell" = {
          enabled-extensions = [ "wsmatrix@martin.zurowietz.de" ];
        };

        # Your custom grid configuration
        "org/gnome/shell/extensions/wsmatrix" = {
          num-rows = lib.gvariant.mkInt32 4;
          num-columns = lib.gvariant.mkInt32 4;
        };
      };
    }
  ];

}
