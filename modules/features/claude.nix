{self, inputs, ...}: {

  flake.nixosModules.claude = { pkgs, ... }: {

    # Claude Desktop (official Linux beta), from poeck/claude-desktop-nix-flake
    imports = [ inputs.claude-desktop.nixosModules.default ];
    programs.claude-desktop.enable = true;
    # The flake lags Anthropic's apt repo; pin the latest .deb ourselves.
    # Newest version + SHA256: https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages
    programs.claude-desktop.package = (pkgs.callPackage "${inputs.claude-desktop}/pkgs/claude-desktop" { }).overrideAttrs (old: rec {
      version = "3.6556.2";
      buildInputs = old.buildInputs ++ [ pkgs.pipewire ];  # 3.x native binding links libpipewire
      src = pkgs.fetchurl {
        url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
        hash = "sha256-D27R8oRcMEGbhUWoMgZ210ZKGfYl4F4CkZI4qml47LQ=";
      };
    });
    # Desktop downloads its own generic-Linux claude-code binary; nix-ld lets it run
    programs.nix-ld.enable = true;

    environment.systemPackages = [
      # Claude Code (CLI), from nixpkgs (unfree)
      pkgs.claude-code
    ];

  };

}
