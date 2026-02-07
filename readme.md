sudo nix-collect-garbage
sudo nix-collect-garbage -d  # deletes older older systems, keeps current
sudo nixos-rebuild boot # run to rebuild grub/systemd boot menus/entries
sudo nix flake update # run this to update then do a flake build switch


nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 14d";
};


# drop into shell with a package that only exists while in the shell 
nix-shell -p htop
