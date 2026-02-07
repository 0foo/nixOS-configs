{ config, pkgs, ... }:

{
  home.username = "nick";
  home.homeDirectory = "/home/nick";

  # Must be set; pick the release you installed HM with.
  home.stateVersion = "25.11";

  # Put “user apps” here (what you previously had in environment.systemPackages).
  home.packages = with pkgs; [
    git
    vscode
    spotify
    monero-cli
    pkgs.nodejs_22
    vlc
    gnome-extension-manager
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    curl
    ghostty
    transmission_4-gtk
    wget
  ];


  # If you want HM to manage Firefox profile settings later, you can enable this.
  # Otherwise, it’s fine to just install firefox via home.packages.
  # programs.firefox.enable = true;

  programs.home-manager.enable = true;
  programs.firefox.enable = true;

  # Hide the duplicate AppStream desktop ID GNOME sometimes surfaces
  xdg.dataFile."applications/com.google.Chrome.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Google Chrome
    NoDisplay=true
    Hidden=true
  '';
}
