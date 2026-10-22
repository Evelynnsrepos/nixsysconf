{ ... }: {

  # Microsoft Teams: there's no official Linux app, teams-for-linux wraps the web version
  flake.nixosModules.teams = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.teams-for-linux ];
  };

}
