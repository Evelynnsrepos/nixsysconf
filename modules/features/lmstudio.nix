{ ... }: {

  # LM Studio: run local AI models (unfree, allowed in configuration.nix)
  flake.nixosModules.lmstudio = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.lmstudio ];
  };

}
