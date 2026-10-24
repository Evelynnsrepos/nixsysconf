{ inputs, ... }: {

  # TeamViewer: remote support (unfree, allowed in configuration.nix).
  # The service runs the teamviewerd daemon and also installs the app.
  flake.nixosModules.teamviewer = { pkgs, ... }: {
    services.teamviewer.enable = true;
    # 15.82.6 from unstable segfaults on start, so it comes from nixpkgs-pinned (15.81.5), see flake.nix
    services.teamviewer.package = (import inputs.nixpkgs-pinned {
      system = pkgs.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    }).teamviewer;
  };

}
