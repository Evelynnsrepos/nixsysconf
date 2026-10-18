{self, inputs, ...}: {

  flake.nixosModules.claude = { pkgs, ... }: {

    environment.systemPackages = [
      # Claude Code (CLI), from nixpkgs (unfree)
      pkgs.claude-code
    ];

  };

}
