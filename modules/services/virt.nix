{ pkgs, ... }:

{

  # ═══════════════════════════════════════════════════════════════════════════════
  # QEMU/KVM + Virt-Manager - Virtualização Completa para Windows
  # ═══════════════════════════════════════════════════════════════════════════════
  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      package = pkgs.qemu_kvm;
      # Aponta libvirt para os JSON descriptors de firmware do QEMU
      # (NixOS não expõe /usr/share/qemu/firmware — necessário para Secure Boot)
      verbatimConfig = ''
        firmware_dir = "${pkgs.qemu_kvm}/share/qemu/firmware"
      '';
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

  # Spice VDAgentd — desabilitado: só faz sentido dentro de uma VM guest,
  # no bare metal gera 180+ erros "No data available" por boot.
  services.spice-vdagentd.enable = false;

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
    virtio-win       # Drivers VirtIO para Windows (ISO)
    win-spice        # SPICE guest tools para Windows

    # ═══ Extras ═══
    spice-gtk        # Suporte SPICE melhorado
  ];

  # libvirt-guests tenta suspender/desligar guests no shutdown e bloqueia ~2min
  # mesmo sem VMs a correr — desativar elimina o stop job lento.
  systemd.services.libvirt-guests.enable = false;

  # Networking bridge para VMs
  networking.firewall.trustedInterfaces = [ "virbr0" ];

  # Autostart da rede 'default' — fora do critical path do boot.
  # Timer de 5s após multi-user evita que os ~250ms do virsh net-start
  # atrasem o graphical.target (estava na critical chain).
  systemd.timers.libvirt-default-network = {
    description = "Delayed start of libvirt default network";
    wantedBy = [ "multi-user.target" ];
    timerConfig = {
      OnActiveSec = "5s";
      Unit = "libvirt-default-network.service";
    };
  };

  systemd.services.libvirt-default-network = {
    description = "Start libvirt default network";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    # Sem wantedBy — ativado pelo timer acima
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 10); do ${pkgs.libvirt}/bin/virsh list --all >/dev/null 2>&1 && break || sleep 0.5; done'";
    };
    script = ''
      ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
      ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
    '';
  };
}
