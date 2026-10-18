{self, inputs, ...}: {

  flake.nixosModules.niri = { pkgs, lib, ... }: {
  programs.niri = {
  enable = true;
  package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
  };
  };

  perSystem = { pkgs, lib, self', ... }: {
	packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      settings = {
              spawn-at-startup = [
          (lib.getExe self'.packages.myNoctalia)
        ];

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

        # Qt/KDE apps read their colours from ~/.config/kdeglobals (Noctalia KColorScheme
        # template) via plasma-integration; qt6ct's palette is ignored by Dolphin/Kate
        environment.QT_QPA_PLATFORMTHEME = "kde";
        input.keyboard = {
          xkb.layout = "de";
        };
        # Focus the window under the cursor (like Hyprland), without scrolling the view to it
        input.focus-follows-mouse = _: {
          props = { max-scroll-amount = "0%"; };
        };

        # Copy of ~/.config/niri/config.kdl, updated with ~/.nixsysconf/sync-niri.sh
        include = "${./niri-config.kdl}";

        outputs = {
          "Acer Technologies ED270U P2 A5381994F3W01" = {   # HDMI-A-1, left
            mode = "2560x1440@119.998";
            position = _: { props = { x = 0; y = 240; }; };
          };
          "Acer Technologies ED270U P2 A43011AD63W01" = {   # DP-2, middle
            mode = "2560x1440@179.998";
            position = _: { props = { x = 2560; y = 240; }; };
          };
          "LG Electronics LG ULTRAGEAR 0x0002F884" = {      # DP-3, right, portrait
            mode = "1920x1080@120.000";
            transform = "90";
            position = _: { props = { x = 5120; y = 0; }; };
          };
        };

        window-rules = [
          {
            # Slight see-through for these apps (Alacritty does its own, see alacritty.toml)
            matches = [
              { app-id = "^discord$"; }
              { app-id = "^Spotify$"; }
              { app-id = "^spotify$"; }
              { app-id = "^org.kde.dolphin$"; }
              { app-id = "^org.kde.kate$"; }
            ];
            opacity = 0.92;
          }
          {
            matches = [ { app-id = "^discord$"; } ];
            open-on-output = "LG Electronics LG ULTRAGEAR 0x0002F884";
          }
          {
            matches = [ { app-id = "^Spotify$"; } ];
            open-on-output = "Acer Technologies ED270U P2 A5381994F3W01";   # left Acer (HDMI-A-1)
          }
        ];

        binds = {
          "Mod+T".spawn-sh = lib.getExe pkgs.alacritty;
          "Mod+Q".close-window = _: { };
          "Mod+D".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
          "Mod+E".spawn-sh = lib.getExe pkgs.kdePackages.dolphin;
          "Mod+A".toggle-overview = _: { };
        };
      };
};
};
}
