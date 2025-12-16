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
      
      # Permite rodar como user normal (não root)
      runAsRoot = false;
    };
    
    # Hook para gerenciamento de recursos (GPU passthrough futuro)
    onBoot = "ignore";
    onShutdown = "shutdown";
  };

  # # Spice USB redirection (permite usar USB do host na VM)
  # virtualisation.spiceUSBRedirection.enable = true;

  # Adiciona usuário ao grupo libvirtd
  users.users.pedrinho.extraGroups = [ "libvirtd" "kvm" ];

  # Pacotes necessários
  environment.systemPackages = with pkgs; [
    # ═══ Core ═══
    virt-manager     # GUI para gerenciar VMs
    virt-viewer      # Visualizador de VMs (SPICE/VNC)
    
    # ═══ CLI Tools ═══
    virtiofsd        # Compartilhamento de pastas host<->guest
    
    # ═══ Windows Guest Tools ═══
    win-virtio       # Drivers VirtIO para Windows (ISO)
    win-spice        # SPICE guest tools para Windows
    
    # ═══ Extras ═══
    spice-gtk        # Suporte SPICE melhorado
    looking-glass-client  # Low-latency para GPU passthrough
  ];

  # # Polkit rules para permitir virt-manager sem sudo
  # security.polkit.extraConfig = ''
  #   polkit.addRule(function(action, subject) {
  #     if (action.id == "org.libvirt.unix.manage" &&
  #         subject.isInGroup("libvirtd")) {
  #       return polkit.Result.YES;
  #     }
  #   });
  # '';

  # # Networking bridge para VMs (opcional mas útil)
  # networking.firewall.trustedInterfaces = [ "virbr0" ];
}

