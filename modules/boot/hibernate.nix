{ ... }:

{
  services.logind.settings.Login = {
    # Lid sem AC → suspend (uso mobile)
    HandleLidSwitch = "suspend";
    # Lid com AC → ignora (monitor externo — não suspende ao fechar o tampo)
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
    # Idle gerenciado pelo hypridle — sem IdleAction aqui pra evitar corrida
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = true;
    AllowHibernation = true;
    AllowSuspendThenHibernate = true;
    SuspendState = "freeze";
    HibernateDelaySec = "30m";
  };

  boot.kernelParams = [
    # Único estado disponível neste hardware (S3/deep não suportado)
    "mem_sleep_default=s2idle"
    "acpi.ec_no_wakeup=1"
  ];

  # Restaura DPMS do Hyprland após qualquer resume (lid open, power button, timer).
  # Sem isso, a tela fica preta após acordar mesmo com Hyprland rodando.
  # Roda como root via system-sleep hook (acesso ao /run/user/<uid> do Hyprland).
  environment.etc."systemd/system-sleep/hyprland-dpms.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      # $1 = pre|post, $2 = suspend|hibernate|hybrid-sleep|suspend-then-hibernate
      [ "$1" = "post" ] || exit 0
      sleep 1  # aguarda DRM e Wayland estabilizarem
      uid=1000
      xdg="/run/user/$uid"
      sig=$(ls "$xdg/hypr/" 2>/dev/null | head -1)
      [ -z "$sig" ] && exit 0
      HYPRLAND_INSTANCE_SIGNATURE="$sig" XDG_RUNTIME_DIR="$xdg" \
        /run/current-system/sw/bin/hyprctl dispatch dpms on >/dev/null 2>&1 || true
    '';
  };
}
