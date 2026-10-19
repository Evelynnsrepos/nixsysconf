{ ... }: {

  # n8n: workflow automation, runs in the background as a system service.
  # Open http://localhost:5678 in the browser; the first visit creates the owner account.
  # Only reachable from this machine (the firewall stays closed).
  flake.nixosModules.n8n = { ... }: {
    services.n8n.enable = true;
  };

}
