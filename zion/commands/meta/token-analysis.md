Análise de consumo de tokens da sessão atual — breakdown por componente, gráfico de barras, e recomendações de otimização.

## O que fazer

Executar esta análise em duas partes: **contexto fixo de boot** (injetado pelo hook) e **contexto acumulado** (conversa + ferramentas).

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

Converter chars → tokens usando aproximação **1 token ≈ 3.5 chars** (PT-BR + box-drawing).

### 2. Estimar overhead fixo da API

| Componente | Estimativa |
|------------|------------|
| System prompt do Claude Code | ~8-12k tk |
| Schema das tools nativas | ~3-5k tk |
| Deferred tools list (nomes apenas) | ~2-3k tk |
| Skills list no system-reminder | ~1.5k tk |

### 3. Estimar contexto acumulado

- Contar turnos de conversa visíveis
- Estimar ~300-800 tokens por turno (pergunta + resposta média)
- Multiplicar pelo número de turnos

### 4. Apresentar infográfico

Exibir resultado como tabela + barras ASCII (`█░`) **agrupadas por dono**, ordenadas do maior pro menor dentro de cada grupo:

Categorias de dono:
- **[NOSSO]** — arquivos que o Zion/NixOS config gera e controla: DIRETRIZES.md, SELF.md, bootstrap.md, GLaDOS.persona.md, avatar/glados.md, LITE block, ENV block, BOOT+API_USAGE block, CLAUDE.md, MEMORY.md
- **[CLAUDE CODE]** — injetado pelo harness do Claude Code (Anthropic distribui, mas nós podemos configurar): System prompt do Claude Code, Schema das tools nativas, Deferred tools list (nomes), Skills list
- **[CONVERSA]** — turnos acumulados (contribuição mista: usuário + modelo)

```
  BREAKDOWN DE TOKENS — sessão atual

  Dono          Componente          Chars     Tokens   Barra (20)            %

  ── NOSSO ──────────────────────────────────────────────────────────────────
  [NOSSO]       DIRETRIZES.md       X chars   X tk     ████████░░░░░░░░░░░░  XX%
  [NOSSO]       Avatar (glados)     X chars   X tk     ██████░░░░░░░░░░░░░░  XX%
  [NOSSO]       GLaDOS.persona      X chars   X tk     █████░░░░░░░░░░░░░░░  XX%
  [NOSSO]       LITE block          estimado  X tk     ███░░░░░░░░░░░░░░░░░  XX%
  [NOSSO]       SELF.md             X chars   X tk     ██░░░░░░░░░░░░░░░░░░  XX%
  [NOSSO]       ENV block           estimado  X tk     ██░░░░░░░░░░░░░░░░░░  XX%
  [NOSSO]       CLAUDE.md           estimado  X tk     █░░░░░░░░░░░░░░░░░░░  XX%
  [NOSSO]       bootstrap.md        X chars   X tk     █░░░░░░░░░░░░░░░░░░░  XX%
  [NOSSO]       MEMORY.md           estimado  X tk     ░░░░░░░░░░░░░░░░░░░░  XX%
  [NOSSO]       BOOT+API_USAGE      estimado  X tk     ░░░░░░░░░░░░░░░░░░░░  XX%
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

Após o breakdown, exibir resumo por dono em barras simples:

```
  NOSSO         ████████░░░░░░░░░░░░  XX%  (~X tk)
  CLAUDE CODE   ██████████████░░░░░░  XX%  (~X tk)
  CONVERSA      ██░░░░░░░░░░░░░░░░░░  XX%  (~X tk)
```

### 5. Recomendações — se $ARGUMENTS contém "rec" ou não tem args

Listar as top 3 otimizações com maior impacto por esforço:

| # | Ação | Economia tk | Esforço | Arquivo afetado |
|---|------|-------------|---------|-----------------|
| 1 | ... | ~Xk | baixo/médio/alto | path |
| 2 | ... | ~Xk | ... | ... |
| 3 | ... | ~Xk | ... | ... |

Focar em:
- **Avatar lazy-load**: injetar só a expressão atual, não as 21 de uma vez
- **`zion_debug=OFF`** por padrão em sessões de projeto externo (não-nixos)
- **DIRETRIZES seccionadas**: injetar só seções relevantes ao contexto
- **Skills list**: filtrar por namespace relevante ao projeto atual

### 6. Contexto de trabalho (se mid-session com código)

Se há ferramentas de leitura de arquivos ou buscas no histórico visível, estimar também:
- Quantos arquivos foram lidos e tamanho médio
- Se há resultados de grep/glob grandes acumulados
- Recomendar: fechar contextos grandes com sumários quando possível

## Args suportados

- sem args → análise completa com recomendações
- `rec` → só recomendações (sem breakdown detalhado)
- `boot` → só overhead de boot (sem conversa)
- `chat` → estimativa só da conversa acumulada
