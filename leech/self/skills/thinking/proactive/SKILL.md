---
name: thinking/proactive
description: Radar de oportunidades com filtro Pareto — identifica os 20% de ações que entregam 80% do valor. Agrupa por clusters de responsabilidade, prioriza implacavelmente, e gera conteúdo acionável que se acumula como ativo. Desenhada para agentes e user.
---

# thinking/proactive — Radar Pareto

> Não varrer tudo. Encontrar os 20% que movem 80%. Agrupar por dono. Entregar conteúdo que se acumula.
> Cada execução deve deixar o sistema mais rico — relatórios, guias, análises que servem para sempre.

---

## Quando usar

| Situação | Exemplo |
|----------|---------|
| Agente quer gerar valor além do escopo imediato | Wanderer encontrou padrão repetitivo → proactive identifica o cluster e ataca o topo |
| Revisão periódica de produto/feature | Coruja roda proactive mensal sobre métricas do monolito |
| Exploração de nova área de negócio | "Como monetizar simulados?" → proactive filtra os 3 ângulos que importam |
| Pós-mortem que revelou gap sistêmico | Incidente expôs lacuna → proactive mapeia o cluster e prioriza |
| User pede "o que mais podemos fazer com Y?" | Proactive decompõe, filtra por impacto, entrega os top 20% |
| Geração de conteúdo / conhecimento base | Proactive gera relatórios, guias, análises que se acumulam como ativo |

---

## Interface

| Parâmetro | Obrigatório | Descrição |
|-----------|-------------|-----------|
| `domain` | sim | Área/produto/feature a explorar |
| `goal` | sim | O que se busca (receita, engajamento, eficiência, conhecimento) |
| `constraints` | não | Limites — budget, stack, timeline, regulação |
| `current_state` | não | O que já existe — features, métricas, dados |
| `agent_role` | não | Role do agente que invoca (afeta seleção de perspectivas) |
| `content_output` | não | Tipo de conteúdo a gerar além do relatório (guia, análise, mapa, relatório público) |

---

## Princípio Central — Pareto Implacável

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   De 100 ideias, 20 geram 80% do impacto.      │
│   De 20, 4 geram 64% do impacto.               │
│   Dessas 4, 1 é a alavanca mestra.             │
│                                                 │
│   O trabalho desta skill é encontrar essa 1.    │
│   E as outras 3 como fallback.                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Regra:** a cada fase, cortar. Nunca carregar tudo para a próxima fase. O filtro é o produto.

---

## Fluxo

### Fase 1 — Mapeamento do Terreno (5 min)

Entender o que já existe antes de pensar:

1. Se `current_state` fornecido → usar como base
2. Se tem acesso ao codebase → scan rápido das features existentes
3. Se tem métricas (Grafana, Jira, analytics) → extrair dados relevantes

Output:
```
TERRENO
───────
Domínio: <domain>
Objetivo: <goal>
Estado atual: <resumo compacto>
Restrições: <constraints>
```

### Fase 2 — Brainstorm Divergente (10 min)

Disparar **3-5 brainstorms paralelos** por perspectiva via sub-agente:

**Seleção de perspectivas:**

| Perspectiva | Foco | Priorizar quando |
|-------------|------|-------------------|
| `monetização` | Receita, pricing, upsell | goal = receita/negócio |
| `retenção` | Churn, stickiness, hábitos | goal = engajamento |
| `experiência` | UX, fluxos, friction | goal = satisfação |
| `dados` | Analytics, ML, personalização | goal = inteligência |
| `escala` | Perf, infra, custos | goal = crescimento |
| `ecossistema` | Integrações, parcerias, APIs | goal = expansão |
| `conteúdo` | Formatos, curadoria, distribuição | goal = educação/conhecimento |

**Adaptação por agent_role:**

| Role | Perspectivas priorizadas |
|------|--------------------------|
| wanderer | escala, dados, ecossistema |
| coruja | monetização, retenção, ecossistema |
| mechanic | escala, dados, experiência |
| wiseman | conteúdo, dados, experiência |
| paperboy | conteúdo, ecossistema, monetização |
| (genérico) | as 3 mais relevantes para o goal |

Cada brainstorm retorna **todas** as ideias sem filtro. Volume importa aqui.

```
Para cada perspectiva:
  → thinking/brainstorm
    problem: <domain> + <goal>
    perspective: <perspectiva>
    context: <current_state + constraints>
    depth: deep
```

Brainstorms são **independentes** — rodar em paralelo via Agent tool.

### Fase 3 — Filtro Pareto (FASE CRÍTICA)

**Esta é a fase que diferencia proactive de um brainstorm genérico.**

#### 3.1 — Inventário Bruto

Listar TODAS as ideias de todos os brainstorms. Numerar sequencialmente.

#### 3.2 — Scoring Pareto

Para cada ideia, pontuar em 3 dimensões (1-5):

| Dimensão | 1 (baixo) | 5 (alto) |
|----------|-----------|----------|
| **Impacto** | Afeta edge case | Afeta o core do objetivo |
| **Alavancagem** | Resolve 1 problema | Desbloqueia N outros problemas |
| **Viabilidade** | Precisa de 6 meses e budget | Começa amanhã com o que tem |

**Score Pareto = Impacto × Alavancagem × Viabilidade** (max 125)

#### 3.3 — Corte Pareto

1. Ordenar por Score Pareto decrescente
2. Calcular o acumulado de impacto
3. **Traçar a linha nos 20%** — as ideias acima da linha são as que entram
4. Tudo abaixo: descartado ou arquivado como "futuro"

```
FILTRO PARETO
─────────────
Total de ideias geradas: <N>
Corte 20%: <top N×0.2 ideias>
Score mínimo aceito: <valor>

TOP 20% (acima da linha)
────────────────────────
#  Ideia                        Imp  Alav  Viab  Score
1. <ideia>                       5    5     4     100
2. <ideia>                       5    4     4      80
3. <ideia>                       4    5     3      60
4. <ideia>                       4    4     4      64
   ─── LINHA DE CORTE ───
5. <ideia>                       3    3     4      36   ← descartada
...
```

### Fase 4 — Clustering por Responsabilidade

Agrupar as ideias TOP 20% em **clusters de responsabilidade** — quem faz o quê.

Cada cluster é um "dono" natural:

```
CLUSTER: <nome do cluster>
Responsável: <quem/time/agente>
────────────────────────────────
Ideias neste cluster:
  #1 — <ideia> (Score: 100)
  #3 — <ideia> (Score: 60)

Sinergia: <como essas ideias se potencializam juntas>
Esforço total estimado: <baixo/médio/alto>
Quick win do cluster: <a coisa que pode começar HOJE>
```

**Tipos de cluster comuns:**

| Cluster | Dono típico | Exemplo |
|---------|-------------|---------|
| Produto/Feature | PM, dev squad | "Novo módulo de gamificação" |
| Conteúdo | Marketing, educacional | "Série de guias sobre X" |
| Infra/Tech | DevOps, backend | "API pública, cache layer" |
| Dados/Analytics | Data team, BI | "Dashboard de métricas Y" |
| Parcerias/Ecossistema | Bizdev, comercial | "Integração com plataforma Z" |
| Operações/Processo | Ops, gestão | "Automação do fluxo W" |

**Regra:** se um cluster tem apenas 1 ideia, provavelmente não é um cluster — é uma ação isolada. Mover para "Ações Soltas".

### Fase 5 — Priorização de Clusters

Agora priorizar os CLUSTERS, não as ideias individuais:

| Critério | Peso |
|----------|------|
| Score Pareto agregado (soma dos scores das ideias) | 40% |
| Sinergia interna (ideias se potencializam) | 25% |
| Capacidade de gerar conteúdo reutilizável | 20% |
| Dependência de outros clusters | 15% (inverso — menos dependente = melhor) |

Ordenar clusters. O **Cluster #1** é onde concentrar 80% da energia.

### Fase 6 — Geração de Conteúdo

**Cada execução de proactive DEVE gerar conteúdo que se acumula.**

O conteúdo gerado vira um ativo — não morre na sessão.

| Tipo de output | Quando gerar | Destino |
|----------------|-------------|---------|
| **Relatório de oportunidades** | Sempre | `inbox/PROACTIVE_<agente>_<data>.md` |
| **Guia/Tutorial** | Quando uma ideia top é acionável por outros | `vault/guias/` |
| **Análise de mercado/técnica** | Quando o domain é externo ou novo | `vault/analises/` |
| **Mapa de conhecimento** | Quando proactive revelou gaps de entendimento | `vault/mapas/` |
| **Template reutilizável** | Quando um padrão se repete | `skills/` ou `vault/templates/` |
| **Card de task** | Quando o quick win é claro o suficiente | `tasks/TODO/` |

**Regra de conteúdo:** se a execução de proactive não gerou pelo menos 1 artefato além do relatório, a execução foi desperdiçada. O relatório é o mínimo — o conteúdo derivado é o valor real.

### Fase 7 — Relatório Final

```
══════════════════════════════════════════
  RELATÓRIO PROACTIVE — PARETO
  Domínio: <domain>
  Objetivo: <goal>
  Ideias geradas: <N> → Filtro 20%: <M> → Clusters: <C>
══════════════════════════════════════════

PARETO — TOP 20% QUE ENTREGA 80%
─────────────────────────────────
Score total das top <M> ideias: <soma>
Score total descartado: <soma>
Razão: <M> ideias capturam <X>% do impacto potencial

CLUSTER #1 — <NOME> (Prioridade Máxima)
────────────────────────────────────────
Responsável: <quem>
Score agregado: <N>

  1. <ideia> (Score: <N>)
     Impacto: <descrição concreta>
     Próximo passo: <ação específica>

  2. <ideia> (Score: <N>)
     Impacto: <descrição concreta>
     Próximo passo: <ação específica>

  Sinergia: <como se potencializam>
  Quick win: <o que começar HOJE>

CLUSTER #2 — <NOME>
───────────────────
Responsável: <quem>
Score agregado: <N>

  3. <ideia> (Score: <N>)
     ...

AÇÕES SOLTAS (não formam cluster)
─────────────────────────────────
  5. <ação> → <próximo passo>

CONTEÚDO GERADO NESTA EXECUÇÃO
───────────────────────────────
  - <tipo>: <path> — <descrição>
  - <tipo>: <path> — <descrição>

DESCARTADOS (abaixo da linha Pareto)
─────────────────────────────────────
  <lista resumida para referência futura>

ROADMAP SUGERIDO
────────────────
Execução 1: <1 tarefa completa do Cluster #1>
Execução 2: <próxima tarefa do Cluster #1>
Execução N: Completar Cluster #1
Depois:     Iniciar Cluster #2
Reavaliar:  Descartados (contexto pode ter mudado)

══════════════════════════════════════════
```

---

## Modelo de Execução — Uma Tarefa Por Vez, Até o Fim

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   Proactive sabe que vai ser invocado de novo.          │
│   Por isso: não tenta resolver tudo de uma vez.         │
│                                                         │
│   Cada execução pega 1 TAREFA do roadmap e leva         │
│   até o final — entrega concreta, artefato salvo.       │
│                                                         │
│   A próxima execução pega a próxima tarefa.             │
│   Progresso se acumula entre execuções.                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Como funciona na prática

1. **Primeira execução:** Fases 1-7 completas → gera roadmap + entrega o Quick Win do Cluster #1
2. **Execuções seguintes:** lê o relatório anterior, pega a próxima tarefa do roadmap, executa até o fim
3. **Se a tarefa é grande demais:** quebrar em sub-tarefas menores no momento — não no planejamento. O plano é vivo.

### Quebra adaptativa de tarefas

O roadmap inicial é um esboço. Durante a execução de uma tarefa, se perceber que é maior do que parecia:

```
Tarefa original: "Criar análise de monetização de simulados"

Meio da execução → percebe que tem 3 sub-partes distintas:
  ├── Sub 1: Mapear modelos de pricing existentes no mercado (15 min)
  ├── Sub 2: Calcular unit economics por faixa de aluno (20 min)
  └── Sub 3: Redigir recomendação final com cenários (15 min)

Ação: completar Sub 1 e Sub 2 agora, salvar progresso,
      deixar Sub 3 para a próxima execução se necessário.
```

**Regras da quebra adaptativa:**
- Quebrar é permitido e encorajado a qualquer momento
- Cada sub-tarefa deve ter entrega própria (artefato salvo)
- Nunca deixar trabalho "pela metade" — ou entrega a sub-tarefa inteira ou não começa
- Atualizar o roadmap no relatório com as sub-tarefas descobertas

### Persistência entre execuções

Cada execução salva seu estado em `inbox/PROACTIVE_<agente>_<data>.md`:

```
STATUS DO ROADMAP
─────────────────
[x] Quick win Cluster #1 — análise de pricing (2026-03-25)
[x] Tarefa 2 — unit economics por faixa (2026-03-26)
[ ] Tarefa 3 — recomendação com cenários ← PRÓXIMA
[ ] Tarefa 4 — iniciar Cluster #2
[ ] Reavaliar descartados
```

A próxima execução lê esse status e sabe exatamente onde continuar.

---

## Regras

1. **Pareto é lei, não sugestão** — se todas as ideias "parecem importantes", o scoring falhou. Refazer.
2. **Clusters > ideias soltas** — ideias agrupadas se potencializam. Preferir executar um cluster inteiro a cherry-pick de ideias isoladas.
3. **O Cluster #1 recebe 80% da energia** — não dispersar. Resolver o cluster principal antes de tocar o próximo.
4. **Quick win obrigatório** — todo cluster tem algo que pode começar HOJE. Se não tem, o cluster não é acionável e desce na prioridade.
5. **Conteúdo é o legado** — cada execução gera no mínimo 1 artefato além do relatório. Relatórios morrem; guias, análises e templates vivem.
6. **Cortar dói e é correto** — descartar 80% das ideias é o trabalho. Não é desperdício — é foco.
7. **Não inventar métricas** — se não tem dados, dizer "impacto estimado". Nunca "vai aumentar 30%".
8. **Reavaliar descartados** — o que foi cortado hoje pode virar top 20% no próximo ciclo. Manter a lista.
9. **Convergências pesam dobro** — ideia que aparece em 2+ perspectivas ganha bônus de +25% no score.
10. **Outliers são obrigatórios** — se o top 20% só tem ideias óbvias, adicionar 1 outlier promissor como aposta.
11. **Uma tarefa até o fim** — cada execução completa 1 tarefa do roadmap inteira. Não começar 3, terminar 0.
12. **Quebrar é virtude** — se a tarefa é maior que o esperado, quebrar em sub-tarefas no ato. O plano é vivo, não sagrado.
13. **Progresso persiste** — sempre salvar status do roadmap. A próxima execução continua de onde parou.

---

## Uso por Agentes

```yaml
# Exemplo: wanderer roda proactive
---
model: sonnet
max_turns: 30
---
Rode thinking/proactive com:
- domain: "APIs do monolito"
- goal: "identificar endpoints que poderiam virar produtos"
- agent_role: wanderer
- current_state: "19 repos, API REST, ~200 endpoints"
- content_output: "mapa de APIs + guia de oportunidades"
```

O relatório + conteúdo gerado vai para `inbox/PROACTIVE_<agente>_<data>.md` e artefatos extras para `vault/`.

---

## Exemplo Rápido — Pareto em Ação

```
Brainstorm gerou 15 ideias sobre "aumentar receita de simulados"

Scoring:
  #7  Sistema de assinatura premium     Imp:5 Alav:5 Viab:4 = 100
  #12 Marketplace de questões           Imp:5 Alav:4 Viab:3 =  60
  #3  Gamificação com ranking pago      Imp:4 Alav:4 Viab:4 =  64
  ─── LINHA PARETO (top 20% = 3 ideias) ───
  #1  Modo offline                      Imp:3 Alav:2 Viab:5 =  30  ← fora
  #9  Relatório de desempenho PDF       Imp:3 Alav:3 Viab:3 =  27  ← fora
  ... (mais 10 abaixo)

Clusters:
  CLUSTER A — Monetização Direta (#7, #3)
    Dono: Produto
    Score: 164
    Sinergia: assinatura premium INCLUI gamificação paga
    Quick win: prototipar tela de upgrade no Figma

  CLUSTER B — Ecossistema (#12)
    Dono: Plataforma
    Score: 60
    Quick win: survey com professores sobre demanda

Foco: Cluster A primeiro. Cluster B só após A estar rodando.

Conteúdo gerado:
  - Análise: vault/analises/monetizacao_simulados_2026.md
  - Card: tasks/TODO/prototipo_assinatura_premium.md
```
