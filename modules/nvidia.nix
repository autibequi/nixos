{ config, pkgs, lib, ... } :
{
  # Configuração manual do driver NVIDIA com a versão mais recente
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/nvidia-x11/default.nix
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "575.51.02";
      sha256_64bit = "sha256-XZ0N8ISmoAC8p28DrGHk/YN1rJsInJ2dZNL8O+Tuaa0=";
      sha256_aarch64 = "sha256-NNeQU9sPfH1sq3d5RUq1MWT6+7mTo1SpVfzabYSVMVI=";
      openSha256 = "sha256-NQg+QDm9Gt+5bapbUO96UFsPnz1hG1dtEwT/g/vKHkw=";
      settingsSha256 = "sha256-6n9mVkEL39wJj5FB1HBml7TTJhNAhS/j5hqpNGFQE4w=";
      persistencedSha256 = "sha256-dgmco+clEIY8bedxHC4wp+fH5JavTzyI1BI8BxoeJJI=";
    };

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = false;
    powerManagement = {
      enable = true;
      finegrained = true;
    };

    # RTX 4060 ainda não é compatível com drivers open source
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    open = true;

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
