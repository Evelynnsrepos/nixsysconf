{ ... }: {

  # btop: resource monitor in the terminal (successor of bashtop, which left nixpkgs)
  flake.nixosModules.btop = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.btop ];
  };

}
