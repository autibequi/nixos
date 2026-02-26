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

    # "ignore" = libvirtd não bloqueia o boot para iniciar VMs/redes.
    # O serviço sobe via socket activation (libvirtd.socket) apenas quando
    # algo realmente o usa — remove ~200ms do critical chain de boot.
    # VMs com autostart ainda sobem, mas em paralelo, fora do caminho crítico.
    onBoot = "ignore";
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
  # Sem sleep: usa ExecStartPre para aguardar o socket do libvirtd ficar pronto,
  # evitando atrasar o boot com um sleep fixo de 2s.
  systemd.services.libvirt-default-network = {
    description = "Start libvirt default network";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Retry for up to ~5s in case libvirtd socket isn't ready yet, no fixed sleep
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 10); do ${pkgs.libvirt}/bin/virsh list --all >/dev/null 2>&1 && break || sleep 0.5; done'";
    };
    script = ''
      ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
      ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
    '';
  };
}
