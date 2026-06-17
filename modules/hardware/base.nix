{ pkgs, ... }:
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

  # Sensores de temperatura/fan. k10temp expõe a temp da CPU AMD (Tctl/Tccd);
  # o comando `sensors` (lm_sensors) lê os hwmon. Fan/temps do superio do ASUS
  # já vêm via asusd (WMI) — ver hardware/asus.nix.
  boot.kernelModules = [ "k10temp" ];
  environment.systemPackages = [ pkgs.lm_sensors ];
}
