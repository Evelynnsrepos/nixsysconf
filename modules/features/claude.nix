{self, inputs, ...}: {

  flake.nixosModules.claude = { pkgs, ... }: {

    # Claude Desktop (official Linux beta), from poeck/claude-desktop-nix-flake
    imports = [ inputs.claude-desktop.nixosModules.default ];
    programs.claude-desktop.enable = true;
    # Desktop downloads its own generic-Linux claude-code binary; nix-ld lets it run
    programs.nix-ld.enable = true;

    environment.systemPackages = [
      # Claude Code (CLI), from nixpkgs (unfree)
      pkgs.claude-code
    ];

  };

}
