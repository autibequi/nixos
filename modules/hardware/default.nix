{ ... }:
{
  # Hardware: drivers, firmware, áudio, periféricos do ASUS Zephyrus G14.
  imports = [
    ./base.nix # firmware + microcode + amdgpu (iGPU)
    ./asus.nix # asusd / supergfxd / rog-control-center
    ./nvidia.nix # dGPU RTX 4060 + PRIME offload
    ./audio.nix # PipeWire
    ./bluetooth.nix
    ./logiops.nix # driver userspace Logitech (HID++)
    # ./ddc.nix # ddcutil + i2c-dev para brilho via DDC/CI
  ];
}
