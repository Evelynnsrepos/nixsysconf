{self, inputs, ...}: {

  flake.nixosModules.myMachineConfiguration = { config, pkgs, ... }: {

    imports =
      [ self.nixosModules.myMachineHardware
        self.nixosModules.claude
        self.nixosModules.niri
        self.nixosModules.millennium
        self.nixosModules.links
        self.nixosModules.home
      ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Use latest kernel.
    boot.kernelPackages = pkgs.linuxPackages_latest;

    networking.hostName = "nixos"; # Define your hostname.

    # Enable networking
    networking.networkmanager.enable = true;

    # Kvantum caps the frame of list items (ItemView) at 6px, which limits how round
    # selections can be. Raise the cap to 24px for KMaterial (~/My-repos/KMaterial-de).
    nixpkgs.overlays = [
      (final: prev: {
        kdePackages = prev.kdePackages.overrideScope (kfinal: kprev: {
          qtstyleplugin-kvantum = kprev.qtstyleplugin-kvantum.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              sed -i -E 's/qMin\(r\.(left|right|top|bottom),6\)/qMin(r.\1,24)/' \
                style/themeconfig/ThemeConfig.cpp
              grep -q 'qMin(r.left,24)' style/themeconfig/ThemeConfig.cpp
            '';
          });
        });
      })
    ];

    # Fish (Alacritty's shell): completions for Nix-installed programs etc.
    programs.fish.enable = true;
    # Fonts: Lexend (UI) and Maple Mono NF (terminals, editors; Nerd Font icons for Starship)
    fonts.packages = [ pkgs.lexend pkgs.maple-mono.NF pkgs.nerd-fonts.jetbrains-mono ];
    # UI font: Lexend Deca (also set in ~/.config/kdeglobals and GTK via gsettings)
    fonts.fontconfig.defaultFonts.sansSerif = [ "Lexend Deca" ];
    fonts.fontconfig.defaultFonts.monospace = [ "Maple Mono NF" ];

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
      emacs-pgtk
      alacritty
      kitty  # Mod+Return; ~/.config/kitty/kitty.conf (cursor trail, Noctalia colours)
      gh
      godot_4_7  # pinned to Godot 4.7.x; plain `godot` follows nixpkgs to newer versions
      (discord.override { withVencord = true; })
      kdePackages.dolphin
      kdePackages.kate
      kdePackages.qt6ct
      kdePackages.plasma-integration  # "kde" Qt platform theme: Qt/KDE apps read Noctalia's kdeglobals
      fluent-icon-theme  # base of the "KMaterial" icon theme (~/My-repos/KMaterial-de/icons)
      kdePackages.qtstyleplugin-kvantum  # Qt style: theme "KMaterial" from ~/My-repos/KMaterial-de (Noctalia user template)
      oreo-cursors-plus  # all Oreo colours; switch with the scripts in ~/claude scripts
      vivaldi
      cargo
      jetbrains-toolbox
      spicetify-cli  # patches the user Flatpak Spotify (com.spotify.Client), themed by Noctalia
      mission-center  # not the Flatpak: its magpie helper runs on the host and needs nix-ld
      fish
      # Fish setup (~/.config/fish/config.fish); Starship gets Noctalia's palette
      starship
      fzf
      zoxide
      eza
      bat
      pkgs.python3
      uv
      kdePackages.filelight
      fishPlugins.fzf-fish
      fishPlugins.autopair
      fastfetch  # runs when Alacritty opens (~/.config/fish/config.fish); config in ~/.config/fastfetch
      fetch  # animated 3D distro-logo fetch (github.com/areofyl/fetch); config in ~/.config/fetch/config
      (mpv.override { scripts = with mpvScripts; [ uosc thumbfast ]; })  # ~/.config/mpv, colours from Noctalia template
      # Default Apps Noctalia plugin (~/My-repos/DefaultAppsNoctaliaPlugin):
      xdg-terminal-exec  # default terminal from ~/.config/xdg-terminals.list (GLib, launchers)
      kdePackages.kservice  # kbuildsycoca6, so running KDE apps pick up new defaults

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
