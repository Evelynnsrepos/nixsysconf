{self, inputs, ...}: {

  flake.nixosModules.myMachineConfiguration = { config, pkgs, ... }: {

    imports =
      [ self.nixosModules.myMachineHardware
        self.nixosModules.claude
        self.nixosModules.niri
        self.nixosModules.millennium
        self.nixosModules.links
        self.nixosModules.home
	self.nixosModules.opentabletdriver
        self.nixosModules.emacs
        self.nixosModules.ai  # LM Studio, Open WebUI, n8n, aider, MCP servers
        self.nixosModules.rustdev
        self.nixosModules.teamviewer
        # self.nixosModules.teams disabled because trash
        self.nixosModules.btop
        self.nixosModules.shell
        self.nixosModules.dev
        self.nixosModules.theming
        self.nixosModules.apps
        self.nixosModules.lix
        # self.nixosModules.cachyos-kernel  # that shit was hacked so zen it is
      ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Zen kernel
    boot.kernelPackages = pkgs.linuxPackages_zen;

    networking.hostName = "evilxOS"; # Define your hostname.

    # Enable networking
    networking.networkmanager.enable = true;

    # Mullvad VPN: daemon + GUI
    services.mullvad-vpn = {
      enable = true;
      gui.enable = true;
    };
    # Mullvad sets its DNS through systemd-resolved
    services.resolved.enable = true;

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

    # Login screen: Noctalia Greeter (greetd) instead of GDM. GNOME stays as a fallback session.
    # If it ever fails to start: Ctrl+Alt+F2, log in, and boot the previous generation.
    services.displayManager.noctalia-greeter = {
      enable = true;
      settings.keyboard.layout = "de";
      passwordlessSyncUsers = [ "evilynn" ];  # Noctalia's "Sync Now" copies wallpaper/colours without a password
    };
    security.pam.services.greetd.enableGnomeKeyring = true;  # GDM unlocked the keyring at login; keep that
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

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

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
