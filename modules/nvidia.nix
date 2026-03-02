{
  config,
  lib,
  ...
}:
{

  boot.kernelModules = [
    "nvidia"
  ];

  services.xserver.videoDrivers = [
    "nvidia"
  ];

  # Workaround conhecido: resume de hibernate com NVIDIA (tela preta/travando)
  # https://discourse.nixos.org/t/psa-for-those-with-hibernation-issues-on-nvidia/61834
  boot.extraModprobeConfig = ''
    options nvidia_modeset vblank_sem_control=0
  '';
  
  # Workaround: driver NVIDIA proprietário conflita com systemd freeze da user session
  # no suspend → resume traz tela preta/travada. Ver nixpkgs#371058.
  systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
  systemd.services.systemd-hibernate.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
  systemd.services.systemd-hybrid-sleep.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

  hardware.nvidia = {
    open = true; # Best compatibility with RTX 4060 mobile Q-Max

    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    nvidiaSettings = false;
    nvidiaPersistenced = false;
    powerManagement = {
      enable = true;
      finegrained = true;
    };


    prime = {
      offload.enable = true; # Modo offload para economia de energia
      offload.enableOffloadCmd = true; # Permite rodar apps na GPU via `nvidia-offload`

      # Configuração de barramento otimizada para G14 com RTX 4060
      amdgpuBusId = lib.mkDefault "PCI:65:0:0";
      nvidiaBusId = lib.mkDefault "PCI:1:0:0";
    };
  };

  # Permite podman usar o driver NVIDIA
  hardware.nvidia-container-toolkit.enable = true;

  # Permite o uso do CUDA
  nixpkgs.config.cudaSupport = true;
}
