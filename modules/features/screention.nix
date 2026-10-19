{self, inputs, ...}: {

  flake.nixosModules.screention = { pkgs, ... }: {

    environment.systemPackages = [
      # Screenshot + annotation tool (Alt+Shift+S, see niri.nix)
      self.packages.${pkgs.stdenv.hostPlatform.system}.screention
    ];

  };

  perSystem = { pkgs, ... }: {
    # Closed-source Tauri app, only shipped as prebuilt files: wrap the AppImage
    packages.screention = pkgs.appimageTools.wrapType2 rec {
      pname = "screention";
      version = "0.12.0";
      src = pkgs.fetchurl {
        url = "https://github.com/gkernel247/screention-releases/releases/download/v${version}/Screention_${version}_amd64.AppImage";
        hash = "sha256-Z9ktOSp3BrtFIl2Rk0y/EJ3/kKCpsf0cF8PrKq37Gv0=";
      };
    };
  };

}
