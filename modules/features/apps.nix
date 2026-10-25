{ ... }: {
  # Desktop apps
  flake.nixosModules.apps = { pkgs, ... }: {
    programs.firefox.enable = true;
    programs.steam.enable = true;
    programs.gamescope.enable = true;
    services.flatpak.enable = true;

    environment.systemPackages = with pkgs; [
      vivaldi
      (discord.override { withVencord = true; })
      spicetify-cli
      (mpv.override {
        scripts = with mpvScripts; [
          uosc
          thumbfast
        ];
      })
      kdePackages.dolphin
      kdePackages.kate
      kdePackages.filelight
      kdePackages.ark
      mission-center
      xdg-terminal-exec
      kdePackages.kservice

      # Gaming tools
      mangohud
      protonup-qt
    ];
  };
}
