---
name: meta:context:boot-debug
description: Debug do pipeline de boot — mostra o que foi carregado nesta sessão, flags ativas, lazy-loads pendentes e recomendações de otimização.
---

# /meta:context:boot-debug — Boot Pipeline Debug

Radiografia do session-start: o que foi injetado, o que ficou de fora, por quê.
Útil para entender contexto inicial, diagnosticar comportamento inesperado e otimizar o boot.

---

## Executar

### 1. Coletar estado do boot

Ler o `session-start.sh` para mapear a lógica de decisão:

```bash
cat /home/claude/.claude/hooks/session-start.sh
```

Detectar valores atuais das flags a partir do contexto de boot injetado no início da sessão
(bloco `---BOOT---` visível no histórico de system-reminders ou inferido pelo que foi carregado).

### 2. Detectar flags e estado real

Para cada flag, determinar:
- **Mecanismo de ativação** (`~/.leech KEY=` ou variável de processo)
- **Default** (o que acontece sem intervenção)
- **Valor nesta sessão** (ON/OFF/0/1/string)
- **Status**: 🔵 ativo · 🔴 inativo · ⚪ lazy (existe mas não carregado)

### 3. Renderizar no Chrome

Gerar conteúdo Markdown em `/tmp/chrome-relay/content.md` e servir via:
```bash
python3 /home/claude/.claude/scripts/chrome-relay.py show /tmp/chrome-relay/content.md
```

Se Chrome offline, imprimir ASCII diretamente no terminal.

---

## Formato de saída

### Intro (sempre no terminal antes de abrir Chrome)

```
          ╭─────╮
          │ ╭─╮ │          /meta:context:boot-debug
          │ │◉│ │          Radiografia do boot desta sessão.
          │ ╰─╯ │          Chrome abrindo...
          ╰─────╯
```

### Tabela de flags (Chrome + ASCII)

**REGRA DE LAYOUT**: emoji sempre na coluna mais à esquerda para alinhamento consistente.

Formato tabela Markdown:
```
|     | Flag | Mecanismo | Default | Valor |
|-----|------|-----------|---------|-------|
| 🔵 | `personality` | `~/.leech PERSONALITY=` | ON | ON |
| 🔴 | `autocommit`  | `~/.leech AUTOCOMMIT=`     | OFF | OFF |
...
```

Substituir valores reais detectados na sessão.

### Pipeline vertical (Chrome + ASCII)

**REGRA DE LAYOUT**: emoji no início de cada linha, antes do conector `├─`.

```
🚀 START
│
🔵 ├─[SEMPRE]────────────────────── BOOT FLAGS
│      datetime · personality · autocommit · in_docker · host_attached...
│
🔵 ├─[leech_debug=OFF + interativo]── LITE.md                    ← ATIVO
🔴 │                                 DIRETRIZES.md              ← requer leech_debug=ON
│
🔵 ├─[SEMPRE]────────────────────── ENV CONTEXT
│
🔴 ├─[usage-bar.txt existe]─────────  API USAGE                 ← arquivo ausente
│
🔴 ├─[AGENT_NAME ou TASK_NAME]──────  AGENT MODE                ← inativo
│
🔵 ├─[SEMPRE]────────────────────── MEMORY RESTORE (N arquivos)
│
🔴 ├─[host_attached=1 + interativo]─────  BOOT DISPLAY              ← requer --host
│
🔴 ├─[beta=ON]───────────────────────  BETA OVERRIDES
│
🔴 └─[LEECH_ANALYSIS_MODE=1]──────────  ANALYSIS MODE

── LAZY-LOAD ─────────────────────────────────────────────────────────
⚪  SELF.md         ~640 tokens  — não carregado
⚪  PERSONALITY.md  ~3.1k tokens — não carregado (inclui avatar GLaDOS)
```

### Recomendações (sempre no final)

Avaliar e exibir recomendações baseadas no estado atual:

```
  RECOMENDAÇÕES PARA ESTA SESSÃO
  ─────────────────────────────────────────────────────────────────

  [gerar dinamicamente baseado nos flags ativos/inativos]

  Exemplos de recomendações possíveis:

  · leech_debug=OFF → PERSONALITY e avatar não carregados
    Se precisar do avatar ou persona completa:
    Editar ~/.leech → LEECH_DEBUG=ON

  · SELF.md não carregado (lazy)
    Se a sessão envolver introspecção ou auto-modificação do sistema:
    invocar skill que carrega SELF.md explicitamente

  · in_docker=1 + host_attached=0 → /workspace/host não montado
    Lab mode inativo. Para editar NixOS/Leech diretamente:
    leech --host (monta /workspace/host)

  · autocommit=OFF (padrão saudável)
    Commits manuais — comportamento correto para sessões interativas.
    Para workers autônomos: Editar ~/.leech → AUTOCOMMIT=ON

  · beta=OFF, analysis_mode=OFF
    Sessão limpa, sem overrides experimentais.

  · MEMORY.md carregado com N arquivos
    Revisar memórias obsoletas periodicamente com /meta:absorb

  COMANDOS ÚTEIS
  ─────────────────────────────────────────────────────────────────
  Ativar modo completo:    Editar ~/.leech → LEECH_DEBUG=ON
  Ativar --host:         leech --host
  Carregar personality:    invocar skill meta:personality (se existir)
  Ver uso de contexto:     /meta:context:usage
  Cristalizar sessão:      /meta:absorb
```

---

## Notas

- Valores detectados devem vir do bloco `---BOOT---` injetado no início da sessão via system-reminder
- Se o bloco BOOT não estiver visível, inferir dos arquivos carregados e do comportamento observado
- Sempre mostrar ASCII no terminal antes (ou se Chrome offline)
- Usar Mermaid flowchart no Chrome para versão visual colorida
