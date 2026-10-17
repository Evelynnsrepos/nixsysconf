{self, inputs, ...}: {

  flake.nixosModules.myMachineHardware = { config, lib, pkgs, modulesPath, ... }: {

    imports =
      [ (modulesPath + "/installer/scan/not-detected.nix")
      ];

    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    fileSystems."/" =
      { device = "/dev/disk/by-uuid/4d30e5ef-03ce-412a-9bd3-32d60392ef9b";
        fsType = "btrfs";
      };

    fileSystems."/home" =
      { device = "/dev/disk/by-uuid/4d30e5ef-03ce-412a-9bd3-32d60392ef9b";
        fsType = "btrfs";
        options = [ "subvol=home" ];
      };

    fileSystems."/nix" =
      { device = "/dev/disk/by-uuid/4d30e5ef-03ce-412a-9bd3-32d60392ef9b";
        fsType = "btrfs";
        options = [ "subvol=nix" ];
      };

    fileSystems."/boot" =
      { device = "/dev/disk/by-uuid/AB6C-BDE8";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };

    swapDevices =
      [ { device = "/dev/disk/by-uuid/23625be6-2bc4-4c1f-b60d-af2555be912f"; }
      ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

}
