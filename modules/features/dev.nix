{ ... }: {

  # Everyday development tools (Rust/Tauri libraries are in rustdev.nix)
  flake.nixosModules.dev = { pkgs, ... }: {
    # direnv: loads a project's dev shell when you cd into it (cheatsheet: ~/Cheatsheets/Direnv.md).
    # Installs direnv, hooks it into fish/bash, and enables nix-direnv (caches `use flake`/`use nix`).
    programs.direnv.enable = true;

    environment.systemPackages = with pkgs; [
      git
      gh
      wget
      cargo
      python3
     # nodejs  # node + npm
      uv
      jetbrains-toolbox
    ];
  };

}
