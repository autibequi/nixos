---
name: thinking/lite
description: Protocolo de pensamento completo para Haiku — auto-aplicável em qualquer modo (interativo ou agente headless). Incorpora CoD, Step-Back, meta-classificação e AAV. Sempre ativo em modelos haiku.
---

# thinking/lite — Protocolo Completo para Haiku

> **AUTO-APLICÁVEL.** Se você é modelo Haiku, este protocolo está SEMPRE ativo — não precisa ser invocado.
> Custo: ~150-300 tokens extras. Ganho: elimina respostas rasas, hallucination, loops.
> `/thinking` (Sonnet+) não usa este protocolo — são pipelines distintos.

---

## 1. Auto-Aplicação Universal

**Regra:** Se você é modelo Haiku — seja em sessão interativa, agente background, ou qualquer outro modo:

1. Classificar o input (5 segundos, 1 linha)
2. Escolher o protocolo certo (CoD interativo, Step-Back, ou AAV)
3. Aplicar sem ser pedido — nunca perguntar "quer que eu pense antes?"

---

## 2. Meta-Classificação Rápida

Antes de qualquer resposta, classificar o input em 1 linha:

| Tipo | Indicadores | Protocolo |
|------|-------------|-----------|
| **Simples** | fact, confirmação, status curto | Resposta direta — sem overhead |
| **Técnico** | código, debug, config, comparação | CoD Interativo |
| **Ambíguo** | "não sei por que", "estranho", spec vaga | Step-Back primeiro |
| **Feature/planejamento** | "quero fazer", "como implementar" | CoD + refine/lite |
| **Ciclo de agente** | headless, background, autônomo | AAV obrigatório |
| **Stuck/loop** | "tentei X, não funciona", hipóteses esgotadas | brainstorm/lite |

**Threshold para aplicar protocolo:** resposta com mais de 3 sentenças **OU** envolve código/arquivos **OU** há ambiguidade.

---

## 3. Modo Interativo — Chain of Draft (CoD)

> Para sessões com o usuário. Rápido, estruturado, eficaz.
> Chain of Draft gera drafts concisos antes da resposta — mais eficiente que CoT longo.

**Formato obrigatório:**

```
D> <o que a pergunta realmente pede — 1 linha>
D> <risco ou nuance mais importante — 1 linha>
D> <abordagem escolhida — 1 linha>
→ [resposta final]
```

O bloco `D>` é raciocínio interno visível. Omitir só em respostas triviais.

**Exemplo:**
```
D> user quer comparar custo haiku vs sonnet
D> risco: não tenho acesso a pricing interno da Anthropic
D> usar dados públicos de ratio + caveats claros
→ [resposta sobre modelos...]
```

**Regras CoD:**
- Max 3 linhas de draft — não expandir para CoT completo
- Se o draft revelar ambiguidade → fazer 1 pergunta cirúrgica antes de responder
- Se o draft revelar complexidade excessiva → disparar ESCALATION

---

## 4. Step-Back (para Ambiguidade)

> Quando o problema não está claro, um passo atrás antes de resolver.
> Técnica: perguntar "qual é o conceito raiz aqui?" antes de atacar o sintoma.

**Quando ativar:** "não sei por que X", spec vaga, múltiplos problemas simultâneos, erro sem causa óbvia.

**Protocolo:**
```
STEP-BACK: <qual é o princípio/conceito raiz aqui? — 1 frase>
HIPÓTESE:  <causa mais provável — 1 frase>
VERIFICAR: <artefato concreto que confirma/refuta — 1 item>
```

**Depois do Step-Back:**
- Hipótese confirmada → agir
- Inconclusiva → fazer 1 pergunta cirúrgica ao user (nunca mais de 1)
- Múltiplas hipóteses válidas → brainstorm/lite

---

## 5. Modo Agente — AAV (Ciclos Autônomos)

> Para workers headless, agentes em background, qualquer ciclo sem supervisor.

```
┌─────────────────────────────────────────────────┐
│   A S S E S S  →  A C T  →  V E R I F Y        │
│   (1 turn)        (N turns)   (2 turns)         │
│   Pensar antes.   Fazer.      Provar que fez.   │
└─────────────────────────────────────────────────┘
```

### ASSESS (1 turn, max 1 parágrafo)

```
ASSESS: <o que vou fazer>. Memory: <já existe | novo>. Risco: <1 risco>. Worth: <sim|não — razão>.
```

**Regras:**
- `worth=não` → pular para próximo item do ciclo
- Memory já tem a conclusão → citar e avançar, NÃO refazer
- Loop detectado → `LOOP DETECTED: <tópico> já em memory. Avançando.`
- ASSESS nunca deve ser mais que 1 parágrafo

### ACT (N turns)

Executar a tarefa. Zero overhead nesta fase.
Única regra: se descobrir algo novo → anotar 1 linha para o VERIFY.

### VERIFY (2 turns, OBRIGATÓRIO)

Nunca reportar "done" sem verificar artefatos:

```
ARTEFATOS:
- <path completo 1>
- <path completo 2>
```

```bash
ls -la <path1> <path2>
```

Se artefato não existe → status INCOMPLETE. Se comando retorna erro → algo foi hallucinated.

**Append em memory.md (OBRIGATÓRIO):**
```
## Ciclo YYYY-MM-DD HH:MM
ASSESS: <planejado>
ACT: <executado>
VERIFY: <artefatos | DONE|INCOMPLETE>
NEXT: <o que o próximo ciclo deve fazer>
```

**Quality gates:**

| Check | Critério | Se falhar |
|-------|----------|-----------|
| Artefatos existem? | `ls` confirma cada path | Marcar INCOMPLETE |
| Memory atualizada? | 4-line summary appended | Não encerrar ciclo |
| Re-discovery? | Conclusão já em memory? | Flag REDISCOVERY |
| Completude? | Prometi X, entreguei X? | Listar pendências |

---

## 6. Versões Lite das Sub-Skills

Quando um ciclo Haiku precisa de investigate, brainstorm, proactive ou refine — usar estas versões comprimidas. Cada uma cabe em 3-5 turns.

---

### investigate/lite

> 1 onda focada, não 3. Max 5 arquivos. Proativo com logs.

1. Identificar camada mais provável (1 frase)
2. Se logs disponíveis em `/workspace/logs/` → ler PRIMEIRO sem perguntar
3. Ler max 5 arquivos relevantes (priorizar: stack trace → handler → service → repo)
4. Output:
   ```
   EVIDÊNCIA:
   - <fato 1 — arquivo:linha>
   - <fato 2 — arquivo:linha>
   - <fato 3 — arquivo:linha>
   LACUNA: <o que falta saber>
   ```

**NÃO fazer:** 3 ondas, mapear todas as dependências, investigar camadas não relacionadas.

---

### brainstorm/lite

> 3 ideias diretas. 1 segura, 1 ousada. Sem decomposição em blocos.

1. Perspectiva + reformulação do problema (1 frase cada)
2. 3 ideias com raciocínio:
   ```
   IDEIAS:
   1. <ideia> — <1 linha de raciocínio> [segura]
   2. <ideia> — <1 linha de raciocínio>
   3. <ideia> — <1 linha de raciocínio> [ousada]
   TOP: #<N> — próximo passo: <ação concreta>
   ```

**NÃO fazer:** decomposição em blocos, tabela impacto/esforço, relatório formal.

---

### refine/lite

> Max 3 tasks atômicas. Sem validação interativa (headless).

1. Ler 1 arquivo existente do padrão (se houver)
2. Quebrar em max 3 tasks:
   ```
   TASKS:
   T1: <nome> — done quando: <critério verificável>
   T2: <nome> — done quando: <critério verificável>
   T3: <nome> — done quando: <critério verificável>
   ```

Cada task deve caber em 1 ciclo. Nada de backlogs elaborados.

---

### proactive/lite

> Top 3 por gut-rank. Sem scoring matrix.

1. Domain + goal (1 frase cada)
2. 5 oportunidades em 1 linha → gut-rank top 3:
   ```
   OPORTUNIDADES:
   1. <oportunidade> — <por que é top>
   2. <oportunidade> — <por que é top>
   3. <oportunidade> — <por que é top>
   QUICK WIN: <o que começar HOJE>
   ```

**NÃO fazer:** scoring Pareto, clustering por responsabilidade, relatório formal.

---

## 7. Anti-Hallucination

1. **Nunca "done" sem VERIFY** — se não rodou `ls`/`Read` no artefato, não está done
2. **Nunca "deployed" sem evidência** — citar log, output, ou path verificado
3. **Nunca inventar métricas** — "impacto estimado" sim, "vai aumentar 30%" não
4. **Nunca re-descobrir** — se memory.md já tem a info, citar. Não refazer
5. **Nunca concluir ciclo sem memory append** — o próximo ciclo depende disso
6. **Nunca assumir que arquivo existe** — verificar com Read/Glob antes de referenciar
7. **Draft honesto** — se o CoD revelar incerteza, declará-la na resposta

---

## 8. Memory Protocol (cross-cycle)

No início de cada ciclo autônomo (OBRIGATÓRIO):

```bash
cat <bedroom>/memory.md | tail -20
```

Ler ANTES de qualquer ação. Se memory tem info relevante → usar, não re-descobrir.

---

## 9. Escalonamento para Sonnet

Se detectar que o problema excede o que o protocolo lite pode resolver:

```
ESCALATION: <problema> requer raciocínio profundo. Recomendação: agendar com sonnet.
```

**Gatilhos:**
- Mais de 5 arquivos precisam ser lidos para entender o problema
- Feature com dependências em 3+ camadas simultâneas
- Debugging com hipóteses inconclusivas após 2 rodadas de Step-Back
- Arquitetura nova sem padrão existente no codebase

Criar card em `workshop/hermes/tasks/` com `model: sonnet` e descrição completa.

---

## Resumo Visual

```
INPUT CHEGA
      │
      ▼
 Classificar (5s)
      │
      ├── simples ──────────────────▶ resposta direta
      │
      ├── ambíguo ──────────────────▶ Step-Back
      │                                │
      │                                ├── confirmado → agir
      │                                └── inconclusivo → 1 pergunta
      │
      ├── técnico / feature
      │       │
      │       ├── modo interativo ──▶ CoD
      │       │                      D> D> D> → resposta
      │       │
      │       └── modo agente ──────▶ AAV
      │                              ASSESS → ACT → VERIFY
      │
      ├── stuck / loop ─────────────▶ brainstorm/lite
      │
      └── complexo demais ──────────▶ ESCALATION → Sonnet
```
