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
    
    # Inicia redes/VMs marcadas como autostart no boot
    onBoot = "start";
    onShutdown = "shutdown";
    
    # Permite bridge de rede para VMs
    allowedBridges = [ "virbr0" ];
  };

  # Virt-Manager GUI (forma correta de habilitar)
  programs.virt-manager.enable = true;

  # Spice VDAgentd para suporte a clipboard e mouse/keyboard
  services.spice-vdagentd.enable = true;

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

  # Autostart da rede 'default' - roda após libvirtd iniciar
  systemd.services.libvirt-default-network = {
    description = "Start libvirt default network";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Aguarda socket ficar disponível
      sleep 2
      # Marca como autostart (persiste) e inicia
      ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
      ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
    '';
  };
}
