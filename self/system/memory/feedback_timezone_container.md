---
name: feedback_timezone_container
description: Container não tem tzdata — usar TZ=UTC+3 (POSIX) para UTC-3, não America/Sao_Paulo
type: feedback
---

O container não tem `tzdata` instalado (`/usr/share/zoneinfo/` não existe). `TZ=America/Sao_Paulo` não funciona — o date retorna "America" como nome de tz e ignora o offset.

Solução: usar formato POSIX `TZ=UTC+3` (que contraditoriamente significa UTC-3 — Pedro está em Brasília/São Paulo, UTC-3).

**Why:** Container minimal NixOS sem tzdata instalado.

**How to apply:** Ao configurar timezone no container (settings.json env, exports em scripts), usar sempre `TZ=UTC+3` para o horário de Brasília. Confirmar com `date "+%Z %z"` — deve mostrar `-0300`.
