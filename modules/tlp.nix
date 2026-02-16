{ lib, ... }:

{
  # TLP e PPD não devem rodar juntos; TLP assume controle
  services.power-profiles-daemon.enable = lib.mkForce false;

  services.tlp = {
    enable = true;
    settings = {
      # AC (conectado à energia)
      # cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
      CPU_BOOST_ON_AC = 1;

      # Battery (na bateria)
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_BOOST_ON_BAT = 0; # pode ser util devido a scx_lavd que agrupa as threads em poucos cores??

      # CPU Driver
      # must be passive/guided for userland schedulers
      # but active is better for battery life
      CPU_DRIVER_OPMODE_ON_AC = "guided";
      CPU_DRIVER_OPMODE_ON_BAT = "guided";

      # GA402X só suporta s2idle (Modern Standby), não S3 deep
      MEM_SLEEP_ON_AC = "s2idle";
      MEM_SLEEP_ON_BAT = "s2idle";

      # ASPM Runtime
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # NVME Power Management (Recomendado para SSDs NVMe)
      NVME_POWER_SAVING_ON_AC = 0; # Desabilitar
      NVME_POWER_SAVING_ON_BAT = 1; # Habilitar

      # plataform
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # ASPM
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersave";
    };
  };
}
