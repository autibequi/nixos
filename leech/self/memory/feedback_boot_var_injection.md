---
name: feedback_boot_var_injection
description: Ao adicionar vars ao BOOT do session-start.sh, não envolver em REGRA — só injetar o dado puro
type: feedback
---

Ao adicionar informação ao bloco `---BOOT---`, injetar o dado diretamente — sem envolver em bloco `REGRA:` a menos que seja de fato uma regra comportamental.

**Why:** Usuário pediu para expor o path do host. A implementação inicial adicionou um bloco REGRA explicativo sobre container/host, exemplo de cursor link, etc. O usuário pediu para desfazer tudo e manter só a linha de dado.

**How to apply:** `echo "host_self=$LEECH_ROOT"` — não `echo "REGRA: container/host — ..."`. Dados são dados, regras são regras. Não pedagogizar o BOOT com explicações que o agente já deve saber.
