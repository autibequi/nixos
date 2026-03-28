---
name: reference_hypridle_logind
description: Conflito entre hypridle e logind no gerenciamento de idle/suspend — como resolver
type: reference
---

# hypridle vs logind — Conflito de gerenciamento de idle

## O problema

Ter `IdleAction = "suspend-then-hibernate"` + `IdleActionSec = "10min"` no logind **enquanto hypridle também gerencia suspend** cria uma corrida: os dois disparam suspend independentemente. Quem ganhar a corrida suspende o sistema — comportamento imprevisível.

## Solução

Deixar **só o hypridle** gerenciar idle/suspend. No logind, remover `IdleAction` e `IdleActionSec`:

```nix
services.logind.settings.Login = {
  HandleLidSwitch = "suspend";
  HandlePowerKey = "suspend";
  HandlePowerKeyLongPress = "poweroff";
  # SEM IdleAction / IdleActionSec — gerenciado pelo hypridle
};
```

## ignore_dbus_inhibit

`ignore_dbus_inhibit = true` no hypridle **quebra inibição de idle** de apps como players de vídeo, videocalls, apresentações. O sistema vai suspender no meio de um vídeo. Manter `false` (default) ou omitir.

## Gap entre lock e suspend

Lock em 600s e suspend em 900s = apenas 5 minutos de gap. Se hyprlock demorar pra iniciar ou o usuário demorar pra reagir, o suspend pode pegar antes da tela de lock estar pronta. Recomendado: lock em ~480s (8min), suspend em ~1200s (20min) — gap de 12min.
