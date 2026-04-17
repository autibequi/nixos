{
  config,
  lib,
  ...
}:
{
  # Política de suspend/mem_sleep: modules/core/hibernate.nix (s2idle por último no cmdline,
  # alinhado com prime offload e comentários nixos-hardware GA402X + TLP).

  # Removido em da40e19f por engano durante refactor — necessário para expor
  # /run/opengl-driver/lib (NVML, VA-API), sem isso btop não deteta a dGPU NVIDIA.
  hardware.graphics.enable = true;

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

    # Patch: Linux 6.18 mudou get_dev_pagemap() para 1 argumento (removeu o 2º arg)
    # nvidia-open 580.105.08 ainda usa a assinatura antiga — fix até upstream corrigir
    package = let
      base = config.boot.kernelPackages.nvidiaPackages.stable;
    in base // {
      open = base.open.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's/get_dev_pagemap(page_to_pfn(page), NULL)/get_dev_pagemap(page_to_pfn(page))/g' \
            kernel-open/nvidia-uvm/uvm_va_range_device_p2p.c
        '';
      });
    };
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

  # Workaround: driver NVIDIA proprietário conflita com systemd freeze da user session
  # no suspend → resume traz tela preta/travada. Ver nixpkgs#371058.
  systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
  systemd.services.systemd-hibernate.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
  systemd.services.systemd-hybrid-sleep.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

  # Permite containers usar o driver NVIDIA
  hardware.nvidia-container-toolkit.enable = true;

  # nvidia-powerd não existe no NixOS e não serve para GPUs mobile.
  # supergfxd tenta iniciar e falha no boot — stub para silenciar.
  systemd.services.nvidia-powerd = {
    description = "NVIDIA powerd stub (not needed for mobile GPUs)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/true";
      RemainAfterExit = true;
    };
  };

  # CUDA global desabilitado: forçava TODOS os pacotes compatíveis a compilar com CUDA,
  # causando builds gigantes e cache misses no Nix. Para usar CUDA em apps específicos:
  #   nix-shell -p cudatoolkit
  #   ou pkgs.python3Packages.torch.override { cudaSupport = true; }
  nixpkgs.config.cudaSupport = true;
}
