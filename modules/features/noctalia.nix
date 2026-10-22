{ self, inputs, ... }: {
  perSystem = { system, ... }: {
    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      # older nixpkgs on purpose, see nixpkgs-pinned in flake.nix
      pkgs = inputs.nixpkgs-pinned.legacyPackages.${system};

    };
  };
}
