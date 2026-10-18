{self, inputs, ...}: {

  flake.nixosModules.niri ={ pkgs, lib, ... }; {
  programs.niri = {
  enable = true;
  package = self.packages.${pkgs.stdenv.honstPlatform.system}.myNiri;
  }
  };
  perSystem = { pkgs, lib, ... }: {

    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      settings = {
        input.keyboard = {
          xkb.layout = "de";
        };

        layout.gaps = 5;

        binds = {
          "Mod+T".spawn-sh = lib.getExe pkgs.alacritty;
          "Mod+Q".close-window = _: { };
        };
      };
    };

  };

}
