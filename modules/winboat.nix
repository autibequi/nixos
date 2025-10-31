{ inputs, pkgs, ... }:

{
  imports = [
    inputs.winboat.nixosModules.default
  ];

  # Habilita WinBoat
  programs.winboat = {
    enable = true;
    
    # Configurações básicas
    # package = inputs.winboat.packages.${pkgs.system}.default;
    
    # Configurações opcionais
    # autoStart = true;
    # windowManager = "gnome"; # ou "kde", "hyprland", etc
  };

  # Dependências necessárias
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };

  # Adiciona o usuário ao grupo libvirtd
  users.users.pedrinho.extraGroups = [ "libvirtd" ];

  # Pacotes necessários
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
    looking-glass-client
  ];
}

