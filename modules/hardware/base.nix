{ pkgs, ... }:
{
  # Drivers de vídeo: amdgpu (iGPU Radeon 780M). O driver `nvidia` é adicionado
  # em nvidia.nix — videoDrivers é lista, então os dois coexistem (PRIME offload).
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Firmware / microcode
  # enableAllFirmware/enableAllHardware removidos (2026-07-02): confirmado via
  # `journalctl -k -b | grep firmware` que todo hardware real (amdgpu, amdxdna,
  # iwlwifi, bluetooth intel, cs35l41 speaker amp) já é coberto pelo
  # linux-firmware redistribuível. As duas flags só adicionavam firmware
  # não-redistribuível extra (~1-1.5GB no store) que nenhum device pede.
  hardware = {
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
