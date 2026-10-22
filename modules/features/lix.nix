{ ... }: {

  # Lix instead of CppNix as the Nix implementation (https://lix.systems/add-to-config/).
  # The overlay builds the Nix tools that link against Nix with Lix as well.
  flake.nixosModules.lix = { pkgs, ... }: {
    nixpkgs.overlays = [
      (final: prev: {
        inherit (prev.lixPackageSets.stable) nixpkgs-review nix-eval-jobs nix-fast-build colmena;
      })
    ];
    nix.package = pkgs.lixPackageSets.stable.lix;
  };

}
