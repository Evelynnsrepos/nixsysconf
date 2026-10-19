{self, inputs, ...}: {

  # Home Manager: manages ~/ (dotfiles, user programs) as part of nixos-rebuild.
  flake.nixosModules.home = { ... }: {

    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;    # same nixpkgs (overlays, allowUnfree) as the system
      useUserPackages = true;  # user packages go to /etc/profiles/per-user, not ~/.nix-profile
      # If a file Home Manager wants to manage already exists, rename it to *.hm-backup
      # instead of failing
      backupFileExtension = "hm-backup";

      users.evilynn = { config, ... }: let
        # Live links into the repo (not read-only store copies): apps and Noctalia's
        # colour templates can keep writing, and edits show up in git right away.
        # Whole folders are linked, because apps that save by write-and-rename
        # would replace a link to a single file.
        dotfiles = "${config.home.homeDirectory}/.nixsysconf/dotfiles/config";
        link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
      in {
        home.stateVersion = "26.05";

        # Fonts stay configured system-wide (configuration.nix), not per user
        fonts.fontconfig.enable = false;

        xdg.configFile = builtins.listToAttrs (map (path: {
          name = path;
          value.source = link path;
        }) [
          "fish"
          "kitty"
          "alacritty"
          "noctalia"
          "mpv"
          "Kvantum"
          "qt6ct"
          "spicetify"
          "millennium"
          "fastfetch"
          "fetch"
          "yazi"
          "Vencord/settings"
        ]);
      };
    };

  };

}
