{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/shared.nix
  ];


services.gnome.gnome-remote-desktop.enable = true;

nixpkgs.config.allowUnfreePredicate = pkg:
  builtins.elem (lib.getName pkg) [ "ngrok" ];

# environment.systemPackages = [ pkgs.ngrok ];

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/session" = {
        idle-delay = lib.gvariant.mkUint32 3600;
      };
    }
  ];

  programs.dconf.enable = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };



  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };


  services.flatpak.enable = true;
  networking.hostName = "precision-5680-2023";
  networking.firewall.checkReversePath = "loose";
  networking.firewall.trustedInterfaces = [ "virbr0" "tailscale0" ];
#  networking.mdns = true;
  
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];

  networking.useHostResolvConf = false;
  networking.networkmanager.dns = "systemd-resolved";

  # Search the tailnet before the AT&T gateway domain. Bare names like "mother"
  # otherwise resolve via attlocal.net to LAN/public-IPv6 addresses where
  # tailnet-only services are not bound, which hangs rather than fails.
  networking.search = [ "tail776145.ts.net" ];

  # Bare hostnames must expand against the tailnet, not the AT&T gateway's
  # attlocal.net. nsswitch uses nss-resolve, so systemd-resolved performs its
  # own search expansion and the search order in resolv.conf is ignored -- and
  # a per-link search domain always beats the global one. So demote the
  # DHCP-supplied attlocal.net to a routing-only domain ("~" prefix): names
  # under it still resolve via the gateway, but it no longer competes to
  # expand bare names like "mother", which would otherwise land on LAN or
  # public-IPv6 addresses where tailnet-only services are not bound.
  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeShellScript "tailnet-search-first" ''
        iface="$1"
        action="$2"
        case "$action" in
          up|dhcp4-change|dhcp6-change) ;;
          *) exit 0 ;;
        esac
        if [ "$iface" = "tailscale0" ]; then exit 0; fi
        doms=$(${pkgs.systemd}/bin/resolvectl domain "$iface" 2>/dev/null)
        # Only act while it is still a search domain (no "~" prefix).
        case "$doms" in
          *"~attlocal.net"*) exit 0 ;;
          *attlocal.net*) ${pkgs.systemd}/bin/resolvectl domain "$iface" "~attlocal.net" ;;
        esac
      '';
    }
  ];

services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = "";
        FallbackDNS = "1.1.1.1";
      };
    };
  };

environment.sessionVariables = {
  LC_TIME = "en_US.UTF-8";
  MOZ_DISABLE_RDD_SANDBOX = "1";
  NVD_BACKEND = "direct";
};

  security.sudo.wheelNeedsPassword = false;

  virtualisation.podman = {
    enable = true;
    # Disable compatibility to prevent socket and alias collisions with real Docker
    dockerCompat = false;
  };

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
    jetbrains.idea
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
    pay-respects
    sqlcmd
    google-chrome
    pgloader
    freetds
#    nomachine-client
    slack

  # needed for labkey tests
  libGL
  stdenv.cc.cc
  libxext
  libxrender
  libxtst
  libxi
  libx11

  # end labkey test packages
  python3
  python3Packages.pip
  # Tulane VPN
  gp-saml-gui
  gpclient
  gnomeExtensions.appindicator
  distrobox 
  git-lfs
  # claude code
  claude-code
  fclones
  samba
  pkgs.ngrok
  paraview
  azure-cli
 ];

  services.transmission.enable = true;

  programs.bash.interactiveShellInit = ''
    eval "$(direnv hook bash)"
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


  services.syncthing = {
    enable = true;
    user = "nick";
    group = "users";
    dataDir = "/home/nick/syncthing";
    configDir = "/home/nick/.config/syncthing";
    openDefaultPorts = true;
    guiAddress = "127.0.0.1:8384";
  };


services.avahi = {
  enable = true;
  nssmdns4 = true;
  openFirewall = true;
};

programs.direnv.enable = true;
}
