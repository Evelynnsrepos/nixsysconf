{self, inputs, ...}: {

  flake.nixosModules.claude = { pkgs, ... }: {

    environment.systemPackages = [
      # Claude Code (CLI), from nixpkgs (unfree)
      pkgs.claude-code

      # Claude Desktop (unofficial community build)
      # -with-fhs so MCP servers started via npx/uvx work on NixOS
      inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-with-fhs
    ];

  };

}
