---
name: meta:tokens
description: Tokens da sessão atual — análise de consumo por componente (breakdown + barras ASCII) ou absorção para reduzir contexto.
---

# /meta:tokens — Gestão de Tokens

```
/meta:tokens           → análise completa com recomendações
/meta:tokens analysis  → breakdown detalhado por componente
/meta:tokens absorb    → sugestões para reduzir contexto agora
/meta:tokens boot      → só overhead de boot
/meta:tokens rec       → só recomendações
```

---

## Roteamento

| Argumento | Ação |
|-----------|------|
| vazio | análise completa + recomendações |
| `analysis` | breakdown detalhado |
| `absorb` | sugestões de redução imediata |
| `boot` | só contexto fixo de boot |
| `rec` | só recomendações |

---

## analysis — Breakdown por componente

### 1. Medir arquivos injetados no boot

```bash
wc -c \
  /workspace/self/system/DIRETRIZES.md \
  /workspace/self/system/SELF.md \
  /workspace/self/personas/GLaDOS.persona.md \
  /workspace/self/personas/avatar/glados.md \
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

Resumo por dono após breakdown:
```
  NOSSO         ████████░░░░░░░░░░░░  XX%  (~X tk)
  CLAUDE CODE   ██████████████░░░░░░  XX%  (~X tk)
  CONVERSA      ██░░░░░░░░░░░░░░░░░░  XX%  (~X tk)
```

---

## absorb — Reduzir contexto agora

Avaliar o que pode ser descartado ou comprimido **nesta sessão**:

1. Identificar tool results grandes no histórico (greps, reads longos)
2. Identificar seções repetidas ou redundantes
3. Sugerir ações concretas:
   - "Este resultado de grep pode ser resumido em X linhas"
   - "Os últimos 3 reads do mesmo arquivo podem ser colapsados"
   - "Considerar /clear e reiniciar com contexto limpo se > 80% do limite"
4. Estimar economia de tokens por ação

---

## rec — Recomendações de otimização

Top 3 otimizações com maior impacto por esforço:

| # | Ação | Economia | Esforço | Arquivo |
|---|------|----------|---------|---------|
| 1 | Avatar lazy-load | ~2k tk | baixo | personas/ |
| 2 | DIRETRIZES seccionadas | ~3k tk | médio | DIRETRIZES.md |
| 3 | Skills list filtrada por namespace | ~1.5k tk | baixo | hook |

---

## observations — Análise de desperdício e otimização

Após o breakdown, gerar esta seção sempre. Observar o histórico da sessão e inferir padrões de desperdício.

### 1. Leituras desnecessárias (reads que não deveriam ter acontecido)

Varrer o histórico de tool calls e identificar:

- **Reads repetidos do mesmo arquivo** — leu o mesmo arquivo 2x sem mudança entre os reads
- **Reads de arquivos grandes para extrair 2 linhas** — deveria ter usado Grep ou offset+limit
- **Reads de arquivos que não eram necessários** — resultado nunca foi usado na resposta
- **Greps retornando resultado completo de arquivo** — sem `| head -N` ou contexto limitado
- **Bash com cat/head quando Read bastaria** — usando shell desnecessariamente

Formato:
```
  ── LEITURAS DESNECESSÁRIAS ──────────────────────────────────────
  ⚠ arquivo.md lido 2x sem mudança entre os reads          ~800 tk desperdiçados
  ⚠ agent.md completo lido para extrair 3 linhas           ~600 tk (use offset+limit)
  ⚠ grep sem | head retornou arquivo inteiro               ~400 tk
  ── total estimado desperdiçado: ~1800 tk (~X% do contexto)
```

### 2. System-reminders pesados

Identificar quais system-reminders aparecem com mais frequência ou são maiores:
- Hooks que reinjetam contexto a cada turno
- Skills list completa em todo turno (quando poderia ser filtrada)
- Boot overhead que poderia ser lazy-loaded

```
  ── SYSTEM-REMINDERS ─────────────────────────────────────────────
  · skills list  aparece em X turnos   ~XXX tk/turno × X = ~Xk tk total
  · boot block   injetado 1x           ~XXk tk fixo
  · hook output  aparece em X turnos   ~XXX tk/turno × X = ~Xk tk total
```

### 3. Recomendações de prompt para o usuário

Dicas concretas de como o usuário pode economizar tokens nas próximas interações:

```
  ── COMO VOCÊ PODE ECONOMIZAR ────────────────────────────────────
  · Em vez de "me mostra o arquivo X", tente:
      "linha 40-60 do arquivo X" → economiza ~70% do read

  · Em vez de perguntas abertas longas, prefira:
      perguntas diretas com contexto mínimo necessário

  · Use /clear quando mudar de assunto completamente
      contexto acumulado de tópico anterior = tokens mortos

  · Ao pedir análise de código, especifique o escopo:
      "função X no arquivo Y" > "o módulo todo"

  · Respostas longas custam tokens também (output):
      "resposta curta" ou "só o essencial" reduz output tokens
```

### 4. Gatilhos de alerta automático

Emitir alertas se:
- Conversa > 25 turnos → sugerir `/clear` com resumo
- Tool results > 500 linhas em um único resultado → avisar desperdício
- Mesmo arquivo lido 3x+ → recomendar cache mental ou nota
- Total estimado > 60k tk → aviso de aproximação do limite
