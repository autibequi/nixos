{ pkgs, ... }:
{
  # curent setup g14
  programs.rog-control-center = {
    enable = true;
    autoStart = false; # crashava 12x — GUI desabilitado no boot, asusd/supergfxd continuam ativos
  };

  services = {
    asusd = {
      enable = true;
    };
    supergfxd = {
      enable = true;
    };
  };

  services.supergfxd.settings = {
    mode = "Hybrid";
    vfio_enable = false;
    vfio_save = false;
    always_reboot = false;
    no_logind = true;
    logout_timeout_s = 180;
    hotplug_type = "None";
  };

  # asusd upstream tem ExecStartPre=sleep 1 (+1.1s no boot).
  # Reduzir para 0.2s — hid_asus já está pronto quando udev termina.
  systemd.services.asusd.serviceConfig.ExecStartPre = [
    "" # limpa o ExecStartPre original (sleep 1)
    "/run/current-system/sw/bin/sleep 0.2"
  ];

  # asus_nb_wmi e asus_wmi são carregados automaticamente pelo udev
  # quando o hardware é detectado — forçar aqui só atrasava
  # systemd-modules-load (~1.7s no critical chain).
  # boot.kernelModules = [ "asus_nb_wmi" "asus_wmi" ];

  # ── Platform profile automático: performance no AC, balanced na bateria ──────
  # O auto-epp (boot/kernel.nix) cuida do EPP do pstate; ISTO cuida do profile do
  # EC (TDP sustentado + fan curve) — onde mora o throttle térmico sob carga.
  # Match por ATTR{type}=="Mains" é robusto contra o nome do adapter (AC0/ADP0/…).
  # (services.udev.extraRules é types.lines → concatena com a regra de boot/kernel.nix.)
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.runtimeShell} -c 'echo performance > /sys/firmware/acpi/platform_profile 2>/dev/null || true'"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.runtimeShell} -c 'echo balanced > /sys/firmware/acpi/platform_profile 2>/dev/null || true'"
  '';

  # ── ryzenadj: ajuste MANUAL de TDP/limites ──────────────────────────────────
  # Undervolt REAL no AMD é PBO Curve Optimizer (BIOS) — não existe via software.
  # ryzenadj ajusta power limits (TDP/temp), não voltagem. Instalado pra você
  # experimentar à mão; SEM service automático porque os valores são específicos
  # do chip+chassis e brigam com o asusd/platform_profile acima.
  #   Ex (no AC): sudo ryzenadj --tctl-temp=95 --stapm-limit=45000 --fast-limit=65000 --slow-limit=45000
  # Pra fixar no boot, descomente e AJUSTE (por sua conta e risco):
  # systemd.services.ryzenadj = {
  #   description = "ryzenadj TDP profile";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.Type = "oneshot";
  #   serviceConfig.ExecStart = "${pkgs.ryzenadj}/bin/ryzenadj --tctl-temp=95 --stapm-limit=45000 --fast-limit=65000";
  # };
  environment.systemPackages = [ pkgs.ryzenadj ];
}
