{ ... }: {

  # Terminals and the fish shell setup (~/.config/fish/config.fish); Starship gets Noctalia's palette
  flake.nixosModules.shell = { pkgs, ... }: {
    # Fish (Alacritty's shell): completions for Nix-installed programs etc.
    programs.fish.enable = true;

    environment.systemPackages = with pkgs; [
      alacritty
      kitty  # Mod+Return; ~/.config/kitty/kitty.conf (cursor trail, Noctalia colours)
      fish
      fishPlugins.fzf-fish
      fishPlugins.autopair
      starship
      fzf
      zoxide
      eza
      bat
      fastfetch  # runs when Alacritty opens (~/.config/fish/config.fish); config in ~/.config/fastfetch
      fetch  # animated 3D distro-logo fetch (github.com/areofyl/fetch); config in ~/.config/fetch/config
    ];
  };

}
