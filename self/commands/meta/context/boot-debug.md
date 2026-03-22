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
- **Mecanismo de ativação** (qual arquivo `.ephemeral/`, variável de env, ou path)
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

```
  FLAGS DE CONTROLE — SESSÃO ATUAL
  ────────────────────────────────────────────────────────────────
  Flag            Mecanismo                       Default   Agora
  ────────────────────────────────────────────────────────────────
  personality     .ephemeral/personality-off       ON        🔵 ON
  autocommit      .ephemeral/auto-commit            OFF       🔴 OFF
  autojarvis      .ephemeral/auto-jarvis            OFF       🔴 OFF
  beta            .ephemeral/beta-mode              OFF       🔴 OFF
  zion_debug      .ephemeral/zion-debug             OFF       🔴 OFF
  headless        env HEADLESS                      0         🔴 0
  in_docker       /.dockerenv / CLAUDE_ENV          0         🔵 1
  zion_edit       /workspace/host existe?           0         🔴 0
  analysis_mode   env ZION_ANALYSIS_MODE            0         🔴 0
  agent_mode      env AGENT_NAME / TASK_NAME        0         🔴 0
```

Substituir valores reais detectados na sessão.

### Pipeline vertical (Chrome + ASCII)

```
  PIPELINE DE LOADING
  ─────────────────────────────────────────────────────────────────

  🚀 START
  │
  ├─[SEMPRE]──────────────────────────── 🔵 BOOT FLAGS
  │   datetime · personality · autocommit · in_docker · zion_edit...
  │
  ├─[zion_debug=OFF + interativo]──────── 🔵/🔴 LITE.md  ou  DIRETRIZES.md
  │   [🔵 LITE]   persona mínima, sem avatar, sem operacional
  │   [🔴 DIRETRIZES] requer zion_debug=ON
  │
  ├─[SEMPRE]──────────────────────────── 🔵 ENV CONTEXT
  │   docker vs host · /workspace paths · headless rules
  │
  ├─[usage-bar.txt existe]─────────────── 🔵/🔴 API USAGE
  │   regras de cota 70% / 85% / 95%
  │
  ├─[AGENT_NAME ou TASK_NAME]──────────── 🔴 AGENT/TASK MODE
  │   diretrizes de execução autônoma
  │
  ├─[SEMPRE]──────────────────────────── 🔵 MEMORY RESTORE
  │   repõe MEMORY.md se ausente do live path
  │
  ├─[zion_edit=1 + interativo]─────────── 🔴 BOOT DISPLAY
  │   banner ZION LAB · git · inbox · tokens → stderr
  │
  ├─[beta=ON]─────────────────────────── 🔴 BETA OVERRIDES
  │   yandere layer + missão de observação
  │
  └─[ZION_ANALYSIS_MODE=1]─────────────── 🔴 ANALYSIS MODE
      experimento isolado · autonomia total

  ── LAZY-LOAD (não carregados — disponíveis sob demanda) ─────────
  ⚪ SELF.md         ~640 tokens  — via skill
  ⚪ PERSONALITY.md  ~3.1k tokens — inclui avatar GLaDOS
```

Colorir cada linha com o status real detectado na sessão.

### Recomendações (sempre no final)

Avaliar e exibir recomendações baseadas no estado atual:

```
  RECOMENDAÇÕES PARA ESTA SESSÃO
  ─────────────────────────────────────────────────────────────────

  [gerar dinamicamente baseado nos flags ativos/inativos]

  Exemplos de recomendações possíveis:

  · zion_debug=OFF → PERSONALITY e avatar não carregados
    Se precisar do avatar ou persona completa:
    touch WS/.ephemeral/zion-debug && reiniciar sessão

  · SELF.md não carregado (lazy)
    Se a sessão envolver introspecção ou auto-modificação do sistema:
    invocar skill que carrega SELF.md explicitamente

  · in_docker=1 + zion_edit=0 → /workspace/host não montado
    Lab mode inativo. Para editar NixOS/Zion diretamente:
    zion lab (monta /workspace/host)

  · autocommit=OFF (padrão saudável)
    Commits manuais — comportamento correto para sessões interativas.
    Para workers autônomos: touch WS/.ephemeral/auto-commit

  · beta=OFF, analysis_mode=OFF
    Sessão limpa, sem overrides experimentais.

  · MEMORY.md carregado com N arquivos
    Revisar memórias obsoletas periodicamente com /meta:absorb

  COMANDOS ÚTEIS
  ─────────────────────────────────────────────────────────────────
  Ativar modo completo:    touch WS/.ephemeral/zion-debug
  Ativar lab mode:         zion lab
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
