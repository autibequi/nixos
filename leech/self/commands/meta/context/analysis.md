---
name: meta:context:analysis
description: Análise completa do contexto da sessão — breakdown por componente, timeline, gráfico de tool calls, velocidade, qualidade, padrões, heat map e grafo de dependência.
---

## Personality

Se uma persona ou avatar estiver ativa (ex: GLaDOS), **sempre** iniciar a resposta desenhando o avatar com uma expressão do catálogo antes de qualquer output de dados. Escolher a expressão com base no tom do resultado (neutro para análise normal, preocupado se contexto crítico, etc). Nunca omitir o avatar quando uma persona estiver carregada — independente do subcomando invocado.

---

# /meta:context:analysis — Análise de Contexto

```
/meta:context:analysis           → análise completa (breakdown + todas as seções)
/meta:context:analysis breakdown → só o breakdown de tokens por componente
/meta:context:analysis boot      → só overhead de boot
/meta:context:analysis absorb    → sugestões para reduzir contexto agora
/meta:context:analysis rec       → só recomendações de otimização
```

---

## Roteamento

| Argumento | Ação |
|-----------|------|
| vazio | análise completa — breakdown + observations (seções 1-10) |
| `breakdown` | só o infográfico de tokens |
| `absorb` | sugestões de redução imediata |
| `boot` | só contexto fixo de boot |
| `rec` | só recomendações |

---

## Breakdown por componente

### 1. Medir arquivos injetados no boot

```bash
wc -c \
  /workspace/leech/system/DIRETRIZES.md \
  /workspace/leech/system/SELF.md \
  /workspace/leech/personas/GLaDOS.persona.md \
  /workspace/leech/personas/avatar/glados.md \
  2>/dev/null
```

Conversão: **1 token ≈ 3.5 chars** (PT-BR + box-drawing).

### 2. Overhead fixo da API

| Componente | Estimativa |
|------------|------------|
| System prompt do Claude Code | ~8-12k tk |
| Schema das tools nativas | ~3-5k tk |
| Deferred tools list | ~2-3k tk |
| Skills list no system-reminder | ~1.5k tk |

### 3. Contexto acumulado

- Contar turnos visíveis × ~300-800 tokens/turno

### 4. Infográfico

```
  BREAKDOWN DE TOKENS — sessão atual

  Dono          Componente          Chars     Tokens   Barra (20)            %

  ── NOSSO ──────────────────────────────────────────────────────────────────
  [NOSSO]       DIRETRIZES.md       X chars   X tk     ████████░░░░░░░░░░░░  XX%
  [NOSSO]       GLaDOS.persona      X chars   X tk     █████░░░░░░░░░░░░░░░  XX%
  [NOSSO]       SELF.md             X chars   X tk     ██░░░░░░░░░░░░░░░░░░  XX%
  [NOSSO]       MEMORY.md           estimado  X tk     ░░░░░░░░░░░░░░░░░░░░  XX%
                                              subtotal  X tk                  XX%

  ── CLAUDE CODE ─────────────────────────────────────────────────────────────
  [CLAUDE CODE] System prompt       estimado  X tk     ████████████████████  XX%
  [CLAUDE CODE] Schema tools        estimado  X tk     ████████░░░░░░░░░░░░  XX%
  [CLAUDE CODE] Deferred tools      estimado  X tk     █████░░░░░░░░░░░░░░░  XX%
  [CLAUDE CODE] Skills list         estimado  X tk     ███░░░░░░░░░░░░░░░░░  XX%
                                              subtotal  X tk                  XX%

  ── CONVERSA ────────────────────────────────────────────────────────────────
  [CONVERSA]    Turnos acumulados   X turnos  X tk     ██░░░░░░░░░░░░░░░░░░  XX%
  [CONVERSA]    system-reminders    estimado  X tk     ██░░░░░░░░░░░░░░░░░░  XX%
                                              subtotal  X tk                  XX%

  Tópicos abordados na sessão:
    · tópico 1                      XX%  ███░░░░░░░░░░░░░░░░░
    · tópico 2                      XX%  ██░░░░░░░░░░░░░░░░░░
    · tópico 3                      XX%  █░░░░░░░░░░░░░░░░░░░
  (% relativo ao total da conversa; estimado por volume de mensagens/tool calls por tópico)

  ────────────────────────────────────────────────────────────────────────────
  TOTAL ESTIMADO    X tk      COM MARGEM ±15%:  X tk – X tk
```

Resumo por dono:
```
  NOSSO         ████████░░░░░░░░░░░░  XX%  (~X tk)
  CLAUDE CODE   ██████████████░░░░░░  XX%  (~X tk)
  CONVERSA      ██░░░░░░░░░░░░░░░░░░  XX%  (~X tk)
```

---

## absorb — Reduzir contexto agora

1. Identificar tool results grandes no histórico (greps, reads longos)
2. Identificar seções repetidas ou redundantes
3. Sugerir ações concretas com estimativa de economia
4. Recomendar `/clear` se > 80% do limite

---

## rec — Recomendações de otimização

Top 3 otimizações com maior impacto por esforço:

| # | Ação | Economia | Esforço | Arquivo |
|---|------|----------|---------|---------|
| 1 | Avatar lazy-load | ~2k tk | baixo | personas/ |
| 2 | DIRETRIZES seccionadas | ~3k tk | médio | DIRETRIZES.md |
| 3 | Skills list filtrada por namespace | ~1.5k tk | baixo | hook |

---

## observations — Análise completa (seções 1-10)

Gerar todas as seções abaixo após o breakdown no modo padrão.

### 1. Leituras desnecessárias

Varrer o histórico de tool calls e identificar:
- Reads repetidos do mesmo arquivo sem mudança entre os reads
- Reads de arquivos grandes para extrair 2 linhas (use Grep ou offset+limit)
- Reads cujo resultado nunca foi usado na resposta
- Greps sem `| head -N`
- Bash com cat/head quando Read bastaria

```
  ── LEITURAS DESNECESSÁRIAS ──────────────────────────────────────
  ⚠ arquivo.md lido 2x sem mudança                  ~800 tk desperdiçados
  ⚠ agent.md completo lido para extrair 3 linhas    ~600 tk (use offset+limit)
  ── total desperdiçado: ~Xk tk (~X% do contexto)
```

### 2. System-reminders pesados

```
  ── SYSTEM-REMINDERS ─────────────────────────────────────────────
  · skills list  aparece em X turnos   ~XXX tk/turno × X = ~Xk tk total
  · boot block   injetado 1x           ~XXk tk fixo
  · hook output  aparece em X turnos   ~XXX tk/turno × X = ~Xk tk total
```

### 3. Recomendações de prompt

```
  ── COMO VOCÊ PODE ECONOMIZAR ────────────────────────────────────
  · "linha 40-60 do arquivo X" em vez de "me mostra X" → -70% do read
  · /clear ao mudar de assunto completamente
  · Especificar escopo: "função X no arquivo Y" > "o módulo todo"
  · "resposta curta" ou "só o essencial" reduz output tokens
```

### 4. Gatilhos de alerta

- Conversa > 25 turnos → sugerir `/clear`
- Tool result > 500 linhas → avisar desperdício
- Mesmo arquivo lido 3x+ → recomendar nota
- Total > 60k tk → aviso de aproximação do limite

### 5. Timeline de arquivos + gráfico de tool calls

Reconstruir cronologia de tool calls. Agrupar 3+ calls temáticos consecutivos.

```
  ── TIMELINE ─────────────────────────────────────────────────────
  │
  ▼ BOOT        ✦ DIRETRIZES · SELF · persona · avatar · MEMORY
  ▼ turno N     · Glob → commands/**
  ▼ turno N     ✦ Read → arquivo.md  |  Edit → arquivo.md
  ▼ turno N     [3 calls — busca de agente]  · grep ✗ · find ✗ · grep ✓
  ▼ agora
```

Legenda: `✦` injetou · `·` lido/descartado · `✗` falhou · `[N]` grupo temático

```
  ── VOLUME POR TURNO ─────────────────────────────────────────────
  BOOT       ████████████████████  ~8k tk
  turno  N   ██░░░░░░░░░░░░░░░░░░  ~X tk
  turno  N   ████████████░░░░░░░░  ~X tk  ← pico (motivo)
```

### 6. Velocidade e projeção

```
  ── VELOCIDADE & PROJEÇÃO ────────────────────────────────────────
  Acumulado: ~Xk tk em N turnos  |  Média: ~X tk/turno  |  Tendência: X
  Restantes: ~Xk tk  |  Turnos restantes: ~N

  ████████████░░░░░░░░░░░░░░░░░░░░  XX% usado
  Segura <60% · Atenção 60-80% · Crítico >80%
```

### 7. Qualidade do contexto

```
  ── QUALIDADE DO CONTEXTO ────────────────────────────────────────
  Redundância: XX%  |  Contexto morto: ~Xk tk  |  Mais antigo: turno N

  Candidatos a descarte:
    · grep turno N (~Xk tk, não referenciado depois)
    · read arquivo.md turno N (~Xk tk, substituído por versão editada)
```

### 8. Padrões de tool calls

```
  ── PADRÕES DE TOOL CALLS ────────────────────────────────────────
  Total: N calls  |  Sucesso: XX%  |  Média: X.X/turno  |  Tendência: X

  Bash    NN  ████████░░  XX%
  Edit    NN  ████░░░░░░  XX%
  Read    NN  ███░░░░░░░  XX%

  Falhas: turno N — motivo | turno N — motivo
```

### 9. Razão user/assistant + heat map do boot

```
  ── RAZÃO USER / ASSISTANT ───────────────────────────────────────
  Input: ~Xk tk XX%  |  Output: ~Xk tk XX%  |  Razão: X.X× (>3 = muito longo)

  ── HEAT MAP DO BOOT ─────────────────────────────────────────────
  DIRETRIZES.md    ████████████  Nx
  GLaDOS.persona   ████░░░░░░░░  Nx
  MEMORY.md        ███░░░░░░░░░  Nx
  glados.avatar    ░░░░░░░░░░░░  0x  ← candidato a lazy-load
```

### 10. Grafo de dependência

```
  ── GRAFO DE DEPENDÊNCIA ─────────────────────────────────────────
  [Read X] → [Edit X] → [Write Y]
  [Glob Z] → [Read Z] → [Bash rm Z]
  [Bash] ✗ → [Bash] ✓ retry   (retry evitável)
```

Identificar chains > 3 steps como potencial de simplificação.
