{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/shared.nix
  ];

  boot.initrd.luks.devices."luks-416c1806-20a2-40f9-ae08-a7ee3b7f86a3".device = "/dev/disk/by-uuid/416c1806-20a2-40f9-ae08-a7ee3b7f86a3";
  networking.hostName = "nuc-desktop";

  services.xserver.displayManager.gdm.wayland = true;

  users.groups.data = {
    gid = 987;
    members = [ "nick" "data" ];
  };

  users.users.nick = {
    extraGroups = [ "data" "libvertd" "kvm" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0BBVKhFXsgGVjUGaxNjLNMiARvGV8SW3davx3I1vEb 0foo@xps13"
    ];
  };

  users.users.data = {
    isNormalUser = true;
    description = "Data owner account";
    group = "data";
    extraGroups = [ "data" ];
    home = "/var/lib/data";
    createHome = true;
    uid = 1001;
  };

  environment.systemPackages = with pkgs; [
    net-tools
    htop
    freerdp
    openssl
    gnome-remote-desktop  
    google-chrome
  ];

  services.tailscale.openFirewall = true;

  networking.firewall.allowedTCPPorts = [ 9000 9443 2283 80 22 ];

  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
    settings = {
      Login = {
        IdleAction = "ignore";
        IdleActionSec = "0";
        HandlePowerKey = "ignore";
        HandleSuspendKey = "ignore";
        HandleHibernateKey = "ignore";
        HandleLidSwitch = "ignore";
        HandleLidSwitchDocked = "ignore";
        HandleLidSwitchExternalPower = "ignore";
      };
    };
  };

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  
  services.gnome.core-utilities.enable = true;
  environment.variables = {
    GSETTINGS_BACKEND = "dconf";
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "yes";
    };
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  programs.virt-manager.enable = true;
}
