{ ... }:
{
  # Drivers de vídeo: amdgpu (iGPU Radeon 780M). O driver `nvidia` é adicionado
  # em nvidia.nix — videoDrivers é lista, então os dois coexistem (PRIME offload).
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Firmware / microcode
  # Stallman would be very sad with me...
  hardware = {
    enableAllFirmware = true;
    enableAllHardware = true;
    enableRedistributableFirmware = true;
    amdgpu.initrd.enable = true;
    cpu.amd.updateMicrocode = true;
  };
}
