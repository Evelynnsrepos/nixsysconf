{ ... }: {

  # TeamViewer: remote support (unfree, allowed in configuration.nix).
  # The service runs the teamviewerd daemon and also installs the app.
  flake.nixosModules.teamviewer = { ... }: {
    services.teamviewer.enable = true;
  };

}
