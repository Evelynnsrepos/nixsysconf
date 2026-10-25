{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    # Noctalia v5 (native rewrite, TOML config in dotfiles/config/noctalia5, linked in home.nix).
    # The v4 config stays in dotfiles/config/noctalia for reference; v5 doesn't read it.
    packages.myNoctalia = pkgs.noctalia;
  };
}
