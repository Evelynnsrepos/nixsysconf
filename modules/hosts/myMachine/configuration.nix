{self, inputs, ...}: {

  flake.nixosModules.myMachineConfiguration = { config, pkgs, ... }: {

    imports =
      [ self.nixosModules.myMachineHardware
        self.nixosModules.claude
        self.nixosModules.spicetify
        self.nixosModules.niri
      ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Use latest kernel.
    boot.kernelPackages = pkgs.linuxPackages_latest;

    networking.hostName = "nixos"; # Define your hostname.

    # Enable networking
    networking.networkmanager.enable = true;

    # Set your time zone.
    time.timeZone = "Europe/Berlin";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_IDENTIFICATION = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_NAME = "de_DE.UTF-8";
      LC_NUMERIC = "de_DE.UTF-8";
      LC_PAPER = "de_DE.UTF-8";
      LC_TELEPHONE = "de_DE.UTF-8";
      LC_TIME = "de_DE.UTF-8";
    };

    # Enable the GNOME Desktop Environment.
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "de";
      variant = "dsb_qwertz";
    };

    # Configure console keymap
    console.keyMap = "de";

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Define a user account. Don't forget to set a password with 'passwd'.
    users.users."evilynn" = {
      isNormalUser = true;
      description = "Evilynn";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [
      #  thunderbird
      ];
    };

    # Install firefox.
    programs.firefox.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # flatpak
    services.flatpak.enable = true;

#steam
programs.steam.enable = true;

    # List packages installed in system profile.
    environment.systemPackages = with pkgs; [
      wget
      git
      emacs-nox
      alacritty
      gh
      godot
      discord
      vencord
      vivaldi
      cargo
      jetbrains-toolbox
      # spotify  # provided by spicetify (modules/features/spicetify.nix)

    ];

    system.stateVersion = "26.05";

    boot.loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
      };
    };

  };

}
