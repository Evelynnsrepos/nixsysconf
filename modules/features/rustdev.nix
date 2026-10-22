{ ... }: {

  # Rustdev: Rust toolchain plus the GTK/WebKit libraries Tauri apps build against
  flake.nixosModules.rustdev = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      rustc
      cargo
      nodejs_22
      pkg-config
      gcc
      dbus
      webkitgtk_4_1
      gtk3
      glib
      cairo
      pango
      gdk-pixbuf
      harfbuzz
      atk
      at-spi2-atk
      libsoup_3
      librsvg
      libayatana-appindicator
      glib-networking
      gsettings-desktop-schemas
      adwaita-icon-theme
    ];
  };

}
