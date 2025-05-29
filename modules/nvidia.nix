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

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    nvidiaSettings = false;
    nvidiaPersistenced = true;
    powerManagement = {
      enable = true;
      finegrained = true;
    };

    open = true; # Best compatibility with RTX 4060 mobile Q-Max

    # Configuração PRIME para laptop híbrido G14
    prime = {
      # TODO: Seria bem legal para melhorar a performace quand conectando um monitor 4k externo
      # Porem atualmente simplesmente trava depois de um tempo. Imagino que arrume rapido.
      # reverseSync.enable = true; # Sincronização reversa para melhorar desempenho
      offload.enable = true; # Modo offload para economia de energia
      sync.enable = false; # Desativado para evitar consumo constante da GPU

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
