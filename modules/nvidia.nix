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
    # Preserva memória de vídeo durante suspend/hibernate — evita freeze pós-resume
    # (nvidia-modeset ACPI backlight hang após s2idle)
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
    options nvidia NVreg_TemporaryFilePath=/tmp
  '';
  
  hardware.nvidia = {
    open = true; # Best compatibility with RTX 4060 mobile Q-Max

    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    nvidiaSettings = false;
    nvidiaPersistenced = false;
    powerManagement = {
      enable = true;
      finegrained = false; # RTD3 incompatível com PRIME offload + s2idle — causa NVRM callback error no resume e trava
    };


    prime = {
      offload.enable = true; # Modo offload para economia de energia
      offload.enableOffloadCmd = true; # Permite rodar apps na GPU via `nvidia-offload`

      # Configuração de barramento otimizada para G14 com RTX 4060
      amdgpuBusId = lib.mkDefault "PCI:65:0:0";
      nvidiaBusId = lib.mkDefault "PCI:1:0:0";
    };
  };

  # Permite containers usar o driver NVIDIA
  hardware.nvidia-container-toolkit.enable = true;

  # Permite o uso do CUDA
  nixpkgs.config.cudaSupport = true;
}
