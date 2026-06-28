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
      #region agent log
      agent_debug_log() {
        ts=$(/run/current-system/sw/bin/date +%s%3N 2>/dev/null || /run/current-system/sw/bin/date +%s)
        state=$(/run/current-system/sw/bin/cat /sys/power/state 2>/dev/null || true)
        mem=$(/run/current-system/sw/bin/cat /sys/power/mem_sleep 2>/dev/null || true)
        wakeup=$(/run/current-system/sw/bin/cat /sys/power/wakeup_count 2>/dev/null || true)
        /run/current-system/sw/bin/printf '{"sessionId":"1605cf","runId":"sleep-power-button","hypothesisId":"S1,S2,S3","location":"modules/boot/hibernate.nix:system-sleep","message":"system-sleep hook","data":{"phase":"%s","verb":"%s","powerState":"%s","memSleep":"%s","wakeupCount":"%s"},"timestamp":%s}\n' "$1" "$2" "$state" "$mem" "$wakeup" "$ts" >> /home/pedrinho/nixos/.cursor/debug-1605cf.log
      }
      agent_debug_log "$1" "$2"
      #endregion
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
