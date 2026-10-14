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

  # CUPS printing with HP drivers (disabled 2026-10-11)
  # services.printing = {
  #   enable = true;
  #   drivers = [ pkgs.hplipWithPlugin ];
  # };

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
  networking.hostName = "nick-dev-precision";
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

  # Tulane's GlobalProtect gateway runs a HIP posture check and puts clients it
  # considers non-compliant into a restricted policy -- DNS and the portal
  # reachable, nothing else, which is the "connects but no traffic" symptom.
  # The HIP report this host sends was accurate on every count except that its
  # antivirus/anti-spyware/anti-malware lists were empty, because nothing was
  # installed. This makes that no longer true.
  #
  # Whether the gateway's policy accepts ClamAV specifically is unknown --
  # posture profiles often allowlist particular vendors -- but it is a real
  # scanner honestly reported, so it is the cheap test before asking Tulane IT
  # which endpoint agent they actually require.
  services.clamav = {
    daemon.enable = true;
    # freshclam, hourly. Keeps <defver> and its datestamp in the HIP report
    # current; a stale signature database is itself a posture failure.
    updater.enable = true;
    # On-access scanning via fanotify -- this is what makes
    # <real-time-protection>yes</real-time-protection> a true statement.
    clamonacc.enable = true;
    # Scheduled scan, so <last-full-scan-time> is a measured value rather than
    # "n/a". Weekly, not nightly: the HIP report only needs a recent successful
    # completion, and the nightly version fired on every morning's resume (a
    # realtime timer whose time passed during suspend runs when the laptop
    # wakes), which is what "clamd is eating the machine" actually was.
    scanner.enable = true;
    scanner.interval = "Sun *-*-* 04:00:00";
    # /home as a whole is ~100G of things no scanner should read: 29G of
    # ~/.cache and 66G of ~/Downloads archives. Scan where fetched content
    # lands and where the posture check cares, and let ExcludePath below cut
    # the churn out of the rest.
    # /tmp and /var/tmp are deliberately absent. They are socket and named-pipe
    # farms on a live desktop -- X11, Chromium's SingletonSocket, dotnet
    # diagnostic pipes -- and clamdscan counts every one as "Not supported file
    # type", an error. Any error at all makes it exit 2, which systemd records
    # as a failed unit, which makes the HIP probe's `Result = success` test
    # false and sends <last-full-scan-time>n/a</last-full-scan-time> forever.
    # A scan that cannot succeed is worse than one with slightly less reach.
    scanner.scanDirectories = [
      "/home/nick/Documents"
      "/home/nick/Desktop"
      "/home/nick/Downloads"
      "/etc"
      "/var/lib"
    ];
    daemon.settings = {
      # Watch the only tree where user-fetched content lands. Scanning the
      # whole filesystem on access would mean scanning the Nix store, which is
      # immutable, already content-addressed, and enormous.
      OnAccessIncludePath = [ "/home" ];
      # OnAccessExcludeUname is already set to "clamav" by the module itself,
      # which is what keeps the scanner from scanning its own reads.
      # Scan on access and alert, but do not block the open() while scanning.
      # Prevention is the stricter setting and ClamAV calls both "on-access";
      # it is off here because blocking reads on /home would be felt
      # immediately by git and node_modules-sized trees. Flip to true if the
      # gateway turns out to want enforcement.
      OnAccessPrevention = false;
      # Default is 12 worker threads, and the scheduled scan runs with
      # --multiscan, so one scan happily occupies 12 of this box's 20 cores.
      # Four is still faster than the disk it reads from.
      MaxThreads = 4;
      # POSIX regex matched against the path, honoured for both on-access
      # requests and clamdscan jobs, since --fdpass hands the work to clamd
      # either way. Build output, caches and VM images are either regenerable,
      # content-addressed, or far too large to be worth hashing.
      ExcludePath = [
        "^/home/[^/]+/\\.cache/"
        "^/home/[^/]+/\\.local/share/Trash/"
        "^/home/[^/]+/\\.local/state/"
        "^/home/[^/]+/\\.mozilla/firefox/[^/]+/(cache2|storage)/"
        "^/home/[^/]+/syncthing/\\.stversions/"
        "^/nix/store/"
        "^/var/lib/(docker|libvirt|containers)/"
        "/node_modules/"
        "/\\.git/objects/"
        "/\\.direnv/"
        "/(site|dist)-packages/"
        "/__pycache__/"
        "/target/(debug|release)/"
      ];
    };
  };

  # Every ClamAV job here is background work with no deadline: the HIP report
  # asks whether the units are running and whether a scan succeeded, never how
  # fast. Giving them SCHED_IDLE and idle I/O means a scan that collides with
  # real work yields instead of competing, and the CPUQuota caps the worst case
  # even when nothing else is runnable.
  systemd.services.clamav-daemon.serviceConfig = {
    Nice = 19;
    CPUSchedulingPolicy = "idle";
    IOSchedulingClass = "idle";
    CPUQuota = "200%";
  };
  systemd.services.clamav-clamonacc.serviceConfig = {
    Nice = 19;
    IOSchedulingClass = "idle";
  };
  systemd.services.clamdscan.serviceConfig = {
    Nice = 19;
    CPUSchedulingPolicy = "idle";
    IOSchedulingClass = "idle";
  };

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
