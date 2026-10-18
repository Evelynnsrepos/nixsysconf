{self, inputs, ...}: {

  flake.nixosModules.spicetify = { pkgs, ... }:
  let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in {

    imports = [
      inputs.spicetify-nix.nixosModules.default
    ];

    # Installs a patched Spotify (unfree), so plain pkgs.spotify isn't needed
    programs.spicetify = {
      enable = true;

      # special characters are dropped from names, e.g. "shuffle+" -> shuffle
 #     enabledExtensions = with spicePkgs.extensions; [
  #      adblock
   #     hidePodcasts
    #    shuffle
     # ];
     
  enabledCustomApps = with spicePkgs.apps; [
    newReleases
    ncsVisualizer
  ];
    enabledSnippets = with spicePkgs.snippets; [
    rotatingCoverart
    pointer
  ];

      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";
    };

  };

}
