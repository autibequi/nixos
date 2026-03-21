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
  /workspace/zion/system/DIRETRIZES.md \
  /workspace/zion/system/SELF.md \
  /workspace/zion/bootstrap.md \
  /workspace/zion/personas/GLaDOS.persona.md \
  /workspace/zion/personas/avatar/glados.md \
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
  [NOSSO]       bootstrap.md        X chars   X tk     █░░░░░░░░░░░░░░░░░░░  XX%
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
                                              subtotal  X tk                  XX%

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
