{ ... }: {

  # Desktop apps
  flake.nixosModules.apps = { pkgs, ... }: {
    programs.firefox.enable = true;
    programs.steam.enable = true;
    services.flatpak.enable = true;

    environment.systemPackages = with pkgs; [
      vivaldi
      (discord.override { withVencord = true; })
      spicetify-cli  # patches the user Flatpak Spotify (com.spotify.Client), themed by Noctalia
      (mpv.override { scripts = with mpvScripts; [ uosc thumbfast ]; })  # ~/.config/mpv, colours from Noctalia template
      kdePackages.dolphin
      kdePackages.kate
      kdePackages.filelight
      kdePackages.ark  # archive manager (zip, tar, 7z ...)
      mission-center  # not the Flatpak: its magpie helper runs on the host and needs nix-ld
      # Default Apps Noctalia plugin (~/My-repos/DefaultAppsNoctaliaPlugin):
      xdg-terminal-exec  # default terminal from ~/.config/xdg-terminals.list (GLib, launchers)
      kdePackages.kservice  # kbuildsycoca6, so running KDE apps pick up new defaults
    ];
  };

}
