{ config, pkgs, ... }:

{
  home.username = "nick";
  home.homeDirectory = "/home/nick";

  # Must be set; pick the release you installed HM with.
  home.stateVersion = "25.11";

  # Put “user apps” here (what you previously had in environment.systemPackages).
  home.packages = with pkgs; [
    firefox
    git
    vscode
    jetbrains.idea-ultimate
    google-chrome
    spotify
    monero-cli

  ];

  # If you want HM to manage Firefox profile settings later, you can enable this.
  # Otherwise, it’s fine to just install firefox via home.packages.
  # programs.firefox.enable = true;

  programs.home-manager.enable = true;


  # Hide the duplicate AppStream desktop ID GNOME sometimes surfaces
  xdg.dataFile."applications/com.google.Chrome.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Google Chrome
    NoDisplay=true
    Hidden=true
  '';
}
