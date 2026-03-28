---
name: thinking/brainstorm
description: Motor de geração de ideias — recebe um problema + perspectiva, decompõe em blocos, ataca um bloco por vez e extrai descobertas acionáveis. Funciona standalone ou como sub-agente invocado por outras skills (ex. proactive).
---

# thinking/brainstorm — Motor de Ideação Estruturada

> Recebe um problema e uma lente. Decompõe, explora, descobre.
> Pode rodar como sub-agente — cada instância ataca uma perspectiva diferente.

---

## Interface

| Parâmetro | Obrigatório | Descrição |
|-----------|-------------|-----------|
| `problem` | sim | Descrição do problema ou área a explorar |
| `perspective` | sim | Lente/ângulo de ataque (ex: "monetização", "UX do aluno", "retenção", "infra/escala", "dados/analytics") |
| `context` | não | Contexto adicional — repo, stack, domínio, restrições |
| `depth` | não | `shallow` (3-5 ideias rápidas) ou `deep` (decomposição completa). Default: `deep` |

---

## Fluxo

### Fase 1 — Enquadramento

Reformular o problema pela lente da perspectiva recebida.

```
Problema original: <problem>
Perspectiva: <perspective>
Reformulação: <problema visto por essa lente>
```

Isso força o brainstorm a não ser genérico — cada perspectiva produz um enquadramento diferente do mesmo problema.

### Fase 2 — Decomposição em Blocos

Quebrar o problema em 3-6 **blocos independentes** que podem ser atacados separadamente.

```
Bloco 1: <nome curto> — <o que cobre>
Bloco 2: <nome curto> — <o que cobre>
Bloco 3: <nome curto> — <o que cobre>
...
```

**Critério de decomposição:**
- Cada bloco deve ser atacável sem depender dos outros
- Blocos devem cobrir o problema inteiro (sem buracos)
- Preferir blocos concretos ("fluxo de checkout") a abstratos ("melhorar a experiência")

### Fase 3 — Ataque por Bloco

Para cada bloco, gerar **3-5 ideias concretas**:

| # | Ideia | Impacto | Esforço | Evidência/Raciocínio |
|---|-------|---------|---------|----------------------|
| 1 | ... | alto/médio/baixo | alto/médio/baixo | por que essa ideia faz sentido |
| 2 | ... | ... | ... | ... |

**Regras de geração:**
- Pelo menos 1 ideia "segura" (incremental, baixo risco)
- Pelo menos 1 ideia "ousada" (muda o jogo, maior risco)
- Ideias devem ser **acionáveis** — não "melhorar X", mas "adicionar Y que faz Z"
- Se o contexto inclui codebase: referenciar pontos reais de extensão

### Fase 4 — Seleção e Priorização

Selecionar as **top 3-5 ideias** do brainstorm inteiro (cross-bloco):

```
DESCOBERTAS
───────────
1. [IMPACTO ALTO | ESFORÇO BAIXO] — <ideia>
   → Próximo passo: <ação concreta>

2. [IMPACTO ALTO | ESFORÇO MÉDIO] — <ideia>
   → Próximo passo: <ação concreta>

3. [IMPACTO MÉDIO | ESFORÇO BAIXO] — <ideia>
   → Próximo passo: <ação concreta>
```

### Fase 5 — Output

**Modo standalone (user invocou direto):**
Entregar as descobertas formatadas + perguntar ao user qual atacar.

**Modo sub-agente (invocado por outra skill):**
Retornar estruturado:

```
BRAINSTORM RESULT
─────────────────
perspective: <perspective>
blocks_analyzed: <N>
ideas_generated: <N>
top_picks:
  - idea: <descrição>
    impact: <alto|médio|baixo>
    effort: <alto|médio|baixo>
    next_step: <ação>
  - ...
```

---

## Uso como Sub-Agente

Outras skills podem invocar brainstorm via Agent tool:

```
Rode thinking/brainstorm com:
- problem: "<descrição do problema>"
- perspective: "<lente específica>"
- context: "<contexto relevante>"
```

Cada instância roda independente — a skill orquestradora (ex: `thinking/proactive`) consolida os resultados.

---

## Modo Debug (quando veio de thinking como fallback)

Quando acionado automaticamente pelo thinking por estar preso num problema técnico, o fluxo muda:

- **Fase 2** decompõe em hipóteses (não blocos de negócio)
- **Fase 3** valida cada hipótese contra artefatos reais (código, logs, config)
- **Fase 4** entrega a hipótese vencedora com evidência

| # | Teoria | Artefato a verificar | Resultado |
|---|--------|----------------------|-----------|
| 1 | ... | arquivo:linha / log / config | CONFIRMADA / REFUTADA / INCONCLUSIVA |

---

## Regras

1. **Perspectiva é obrigatória** — brainstorm sem lente é brainstorm genérico (inútil)
2. **Decompor antes de gerar** — atacar o todo produz ideias vagas
3. **Cada ideia deve ter próximo passo** — ideia sem ação é wishful thinking
4. **Quantidade na geração, qualidade na seleção** — não filtrar cedo demais
5. **Ousadia obrigatória** — pelo menos 1 ideia por bloco que ninguém pediria
