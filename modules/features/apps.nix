{ ... }: {
  # Desktop apps
  flake.nixosModules.apps = { pkgs, ... }: {
    programs.firefox.enable = true;
    programs.steam.enable = true;
    programs.gamescope.enable = true;
    services.flatpak.enable = true;
    # Libraries the Steam Blender needs when run outside Steam (via the link below)
    programs.nix-ld.libraries = with pkgs; [ libsm libice libx11 libxext libxi libxrender libxxf86vm libxfixes libxkbcommon libGL libdecor wayland ];

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
      prismlauncher  # Minecraft
      # `blender` on PATH for Noctalia's Blender theme hook: a link to the Steam copy
      (runCommand "steam-blender" { } "mkdir -p $out/bin; ln -s /home/evilynn/.local/share/Steam/steamapps/common/Blender/blender $out/bin/blender")
    ];
  };
}
