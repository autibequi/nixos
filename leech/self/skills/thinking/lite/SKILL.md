---
name: thinking/lite
description: Protocolo de pensamento compacto para agentes haiku — ASSESS/ACT/VERIFY obrigatório em todo ciclo. Previne output raso, hallucination de completude, e esquecimento cross-cycle. Inclui versões comprimidas de investigate, brainstorm, proactive e refine.
---

# thinking/lite — Pensamento Compacto para Haiku

> Haiku é rápido mas raso. Este protocolo compensa com estrutura.
> Três momentos obrigatórios: antes, durante, depois.
> Custo: ~3 turns. Ganho: elimina hallucination, previne loops, força quality gates.

---

## Quando usar

**SEMPRE** — todo agente haiku, todo ciclo. Não é opcional.
Agentes sonnet podem usar como fallback em ciclos curtos (#steps15 ou menos).

---

## O Protocolo AAV

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   A S S E S S  →  A C T  →  V E R I F Y        │
│   (1 turn)        (N turns)   (2 turns)         │
│                                                 │
│   Pensar antes.   Fazer.      Provar que fez.   │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

### ASSESS (antes de agir — 1 turn, max 1 parágrafo)

Responder estas 4 perguntas em texto corrido:

1. **O que vou fazer?** (1 frase)
2. **Já fiz isso antes?** → checar memory.md PRIMEIRO
3. **O que pode dar errado?** (1 risco concreto)
4. **Vale gastar turns nisso?** (sim/não + justificativa de 1 linha)

Formato obrigatório:
```
ASSESS: <o que vou fazer>. Memory: <já existe | novo>. Risco: <1 risco>. Worth: <sim|não — razão>.
```

**Regras do ASSESS:**
- Se worth=não → pular para próximo item do ciclo
- Se memory.md já tem a conclusão → citar e avançar, NÃO refazer
- Se é re-discovery → `LOOP DETECTED: <tópico> já em memory. Avançando.`
- ASSESS nunca deve ser mais que 1 parágrafo

---

### ACT (executar — N turns)

Executar a tarefa normalmente. Zero overhead nesta fase.

Única regra durante ACT:
- Se descobrir algo novo → anotar em 1 linha para o VERIFY (não interromper para investigar tangentes)

---

### VERIFY (depois de agir — 2 turns, OBRIGATÓRIO)

**Antes de reportar QUALQUER resultado como "done":**

#### 1. Listar artefatos

```
ARTEFATOS:
- <path completo do artefato 1>
- <path completo do artefato 2>
```

#### 2. Confirmar existência

```bash
ls -la <path1> <path2>
```

Se o artefato **não existe** → status é INCOMPLETE, não DONE.
Se o comando retorna erro → algo foi hallucinated.

#### 3. Append em memory.md

```
## Ciclo YYYY-MM-DD HH:MM
ASSESS: <o que planejei>
ACT: <o que fiz de fato>
VERIFY: <artefatos + status DONE|INCOMPLETE>
NEXT: <o que o próximo ciclo deve fazer>
```

#### 4. Quality Gates

| Check | Critério | Se falhar |
|-------|----------|-----------|
| Artefatos existem? | `ls` confirma cada path | Marcar INCOMPLETE |
| Memory atualizada? | 3-line summary appended | Não encerrar ciclo |
| Re-discovery? | Conclusão já em memory? | Flag "REDISCOVERY" |
| Completude? | Prometi X, entreguei X? | Listar pendências |

---

## Regras Anti-Hallucination

1. **Nunca "done" sem VERIFY** — se não rodou `ls`/`Read` no artefato, não está done
2. **Nunca "deployed" sem evidência** — citar log, output, ou path verificado
3. **Nunca inventar métricas** — "impacto estimado" ok, "vai aumentar 30%" não
4. **Nunca re-descobrir** — se memory.md já tem a info, citar. Não refazer a pesquisa
5. **Nunca concluir ciclo sem memory append** — o próximo ciclo depende disso

---

## Memory Protocol (cross-cycle)

### No início do ciclo (OBRIGATÓRIO):

```bash
cat <bedroom>/memory.md | tail -20
```

Ler ANTES de qualquer ação. Se memory tem info relevante → usar, não re-descobrir.

### No final do ciclo (OBRIGATÓRIO):

Append em memory.md no formato:
```
## Ciclo YYYY-MM-DD HH:MM
ASSESS: <planejado>
ACT: <executado>
VERIFY: <artefatos | status>
NEXT: <próximo ciclo>
```

### Detecção de loops:

Se ASSESS identifica que memory.md já tem a mesma conclusão:
```
LOOP DETECTED: <tópico> já investigado em <data>. Ação: avançar, não repetir.
```

---

## Versões Lite das Sub-Skills

Quando um haiku precisa de brainstorm, investigate, proactive, ou refine — usar estas versões comprimidas. Cada uma cabe em 3-5 turns.

---

### investigate/lite

> 1 onda focada, não 3. Max 5 arquivos.

1. Identificar a camada mais provável do problema (1 frase)
2. Ler max 5 arquivos relevantes
3. Output:
   ```
   EVIDÊNCIA:
   - <fato 1>
   - <fato 2>
   - <fato 3>
   LACUNA: <o que falta saber>
   ```
4. NÃO fazer 3 ondas. NÃO mapear dependências. Foco cirúrgico.

---

### brainstorm/lite

> 3 ideias diretas, sem decomposição em blocos.

1. Problema + perspectiva (1 frase cada)
2. 3 ideias concretas:
   ```
   IDEIAS:
   1. <ideia> — <1 linha de raciocínio>
   2. <ideia> — <1 linha de raciocínio>
   3. <ideia> — <1 linha de raciocínio>
   TOP: #<N> — próximo passo: <ação>
   ```
3. NÃO decompor em blocos. NÃO fazer tabelas de impacto/esforço.
4. Regra: pelo menos 1 ideia "segura" e 1 "ousada".

---

### proactive/lite

> Top 3 por gut-rank, sem scoring matrix.

1. Domain + goal (1 frase cada)
2. Listar 5 oportunidades em 1 linha cada
3. Gut-rank top 3 com rationale de 1 linha:
   ```
   OPORTUNIDADES:
   1. <oportunidade> — <por que é top>
   2. <oportunidade> — <por que é top>
   3. <oportunidade> — <por que é top>
   QUICK WIN: <o que começar HOJE>
   ```
4. NÃO fazer scoring Pareto (Impacto × Alavancagem × Viabilidade)
5. NÃO fazer clustering por responsabilidade
6. NÃO gerar relatório formal — o output acima é suficiente

---

### refine/lite

> Max 3 tasks, sem validação interativa.

1. Ler 1 arquivo existente do padrão (se houver)
2. Quebrar em max 3 tasks atômicas:
   ```
   TASKS:
   T1: <nome> — done quando: <critério>
   T2: <nome> — done quando: <critério>
   T3: <nome> — done quando: <critério>
   ```
3. NÃO fazer validação com o user (headless, não tem user)
4. NÃO criar backlog elaborado — 3 tasks é o máximo
5. Cada task deve caber em 1 ciclo do agente

---

## Quando escalar para a versão completa

Se o agente haiku detectar que o problema é complexo demais para lite:

```
ESCALATION: <problema> excede capacidade lite. Recomendação: agendar com sonnet.
```

Criar card em `workshop/hermes/tasks/` com `model: sonnet` e a descrição do que precisa ser feito. Não tentar resolver com haiku o que precisa de sonnet.

---

## Resumo Visual

```
INÍCIO DO CICLO
      │
      ▼
  Ler memory.md (tail -20)
      │
      ▼
  ┌─────────┐
  │ ASSESS  │  O que? Já fiz? Risco? Worth?
  └────┬────┘
       │
       ├── worth=não → pular
       ├── loop detected → avançar
       │
       ▼
  ┌─────────┐
  │  ACT    │  Executar (0 overhead)
  └────┬────┘
       │
       ▼
  ┌─────────┐
  │ VERIFY  │  ls artefatos + quality gates
  └────┬────┘
       │
       ├── artefato não existe → INCOMPLETE
       ├── memory append (4 linhas)
       │
       ▼
  FIM DO CICLO
```
