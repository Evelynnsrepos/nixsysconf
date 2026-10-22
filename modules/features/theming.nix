{ ... }: {

  # Look and feel: fonts, Qt/KDE theming (KMaterial, ~/My-repos/KMaterial-de), icons, cursors
  flake.nixosModules.theming = { pkgs, ... }: {
    # Fonts: Lexend (UI) and Maple Mono NF (terminals, editors; Nerd Font icons for Starship)
    fonts.packages = [ pkgs.lexend pkgs.maple-mono.NF pkgs.nerd-fonts.jetbrains-mono ];
    # UI font: Lexend Deca (also set in ~/.config/kdeglobals and GTK via gsettings)
    fonts.fontconfig.defaultFonts.sansSerif = [ "Lexend Deca" ];
    fonts.fontconfig.defaultFonts.monospace = [ "Maple Mono NF" ];

    # Kvantum caps the frame of list items (ItemView) at 6px, which limits how round
    # selections can be. Raise the cap to 24px for KMaterial (~/My-repos/KMaterial-de).
    nixpkgs.overlays = [
      (final: prev: {
        kdePackages = prev.kdePackages.overrideScope (kfinal: kprev: {
          qtstyleplugin-kvantum = kprev.qtstyleplugin-kvantum.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              sed -i -E 's/qMin\(r\.(left|right|top|bottom),6\)/qMin(r.\1,24)/' \
                style/themeconfig/ThemeConfig.cpp
              grep -q 'qMin(r.left,24)' style/themeconfig/ThemeConfig.cpp
            '';
          });
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      kdePackages.qt6ct
      kdePackages.plasma-integration  # "kde" Qt platform theme: Qt/KDE apps read Noctalia's kdeglobals
      kdePackages.qtstyleplugin-kvantum  # Qt style: theme "KMaterial" from ~/My-repos/KMaterial-de (Noctalia user template)
      fluent-icon-theme  # base of the "KMaterial" icon theme (~/My-repos/KMaterial-de/icons)
      oreo-cursors-plus  # all Oreo colours; switch with the scripts in ~/claude scripts
    ];
  };

}
