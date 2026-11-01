{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Last nixpkgs where everything built (2026-10-14), for packages broken on current unstable:
    # Open WebUI and aider (posthog marked broken with mcp 2), mcp-proxy (0.13.0 needs mcp<2),
    # TeamViewer (15.82.6 segfaults).
    # Drop a use once that package builds on unstable again; drop the input when none is left.
    nixpkgs-pinned.url = "github:nixos/nixpkgs/55bfb4d7437bd4e09ab7cba58a43bd68eb310044";

    # Discord 1.0.168 fixes black incoming streams; nixos-unstable is still on 1.0.161.
    # Drop this input (and its use in apps.nix) once nixos-unstable has 1.0.168.
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    # Steam with Millennium (used via its overlay, so it builds against our nixpkgs)
    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";

    # Claude Desktop (official Linux beta)
    claude-desktop.url = "github:poeck/claude-desktop-nix-flake";
    claude-desktop.inputs.nixpkgs.follows = "nixpkgs";

    # CachyOS kernels (patches + tunings), prebuilt in the author's binary cache (see cachyos-kernel.nix).
    # Do not make it follow our nixpkgs: its pinned nixpkgs is what the cached kernels were built with.
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Home Manager (master tracks nixos-unstable)
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
