{ ... }: {

  # Everyday development tools (Rust/Tauri libraries are in rustdev.nix)
  flake.nixosModules.dev = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      gh
      wget
      cargo
      python3
      nodejs  # node + npm
      uv
      jetbrains-toolbox
      dirvenv
    ];
  };

}
