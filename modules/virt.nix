{ pkgs, ... }:

{
  # ═══════════════════════════════════════════════════════════════════════════════
  # QEMU/KVM + Virt-Manager - Virtualização Completa para Windows
  # ═══════════════════════════════════════════════════════════════════════════════

  virtualisation.libvirtd = {
    enable = true;
    
    # QEMU com suporte UEFI (OVMF) - essencial para Windows 11
    qemu = {
      package = pkgs.qemu_kvm;
      
      # UEFI Firmware para VMs (Windows 11 exige)
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
      
      # TPM virtual (Windows 11 exige)
      swtpm.enable = true;
    };
    
    # Hook para gerenciamento de recursos (GPU passthrough futuro)
    onBoot = "ignore";
    onShutdown = "shutdown";
  };

  # Virt-Manager GUI (forma correta de habilitar)
  programs.virt-manager.enable = true;

  # Dconf para virt-manager salvar configurações
  programs.dconf.enable = true;

  # Adiciona usuário aos grupos necessários
  users.users.pedrinho.extraGroups = [ "libvirtd" "kvm" ];

  # Pacotes necessários
  environment.systemPackages = with pkgs; [
    # ═══ Core ═══
    virt-viewer      # Visualizador de VMs (SPICE/VNC)
    dmidecode        # Info de hardware (libvirt precisa)
    
    # ═══ CLI Tools ═══
    virtiofsd        # Compartilhamento de pastas host<->guest
    
    # ═══ Windows Guest Tools ═══
    win-virtio       # Drivers VirtIO para Windows (ISO)
    win-spice        # SPICE guest tools para Windows
    
    # ═══ Extras ═══
    spice-gtk        # Suporte SPICE melhorado
  ];

  # Networking bridge para VMs
  networking.firewall.trustedInterfaces = [ "virbr0" ];
}
