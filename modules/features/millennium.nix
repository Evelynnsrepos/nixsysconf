{self, inputs, ...}: {

  # Millennium: Steam modding (themes/plugins); Noctalia themes Steam through it
  # (Material-Theme with the "Matugen" colour option).
  flake.nixosModules.millennium = { pkgs, ... }: {

    nixpkgs.overlays = [ inputs.millennium.overlays.default ];

    programs.steam.package = pkgs.millennium-steam;

  };

}
