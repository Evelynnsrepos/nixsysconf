{ inputs, ... }: {

  # CachyOS kernel (github.com/xddxdd/nix-cachyos-kernel), x86_64-v3 build for the i7-10700F.
  # AMD GPU, so no out-of-tree driver has to match it. Prebuilt kernels come from the author's
  # binary cache; without it, every kernel update compiles locally (about an hour).
  flake.nixosModules.cachyos-kernel = { pkgs, ... }: {
    nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
    boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;


    # Binary cache: offline since the author's servers were compromised on 2026-10-15
    # (github.com/xddxdd/nix-cachyos-kernel/issues/110). Add it back, with whatever key the
    # README lists then, once it is restored:
    # nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
    # nix.settings.trusted-public-keys = [ "lantian:..." ];
  };

}
