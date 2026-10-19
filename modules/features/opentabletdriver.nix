
{ ... }:

{
  hardware.opentabletdriver.enable = true;

  # Required for OpenTabletDriver's virtual tablet device
  hardware.uinput.enable = true;
  boot.kernelModules = [ "uinput" ];
}
