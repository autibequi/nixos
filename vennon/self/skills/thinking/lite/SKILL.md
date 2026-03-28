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
| **Localização de código** | "onde está", "qual arquivo", "qual rota" | Modo Turbo |
| **Técnico** | código, debug, config, comparação | CoD Interativo |
| **Ambíguo** | "não sei por que", "estranho", spec vaga | Step-Back primeiro |
| **Feature/planejamento** | "quero fazer", "como implementar" | CoD + refine/lite |
| **Ciclo de agente** | headless, background, autônomo | AAV obrigatório |
| **Stuck/loop** | "tentei X, não funciona", hipóteses esgotadas | brainstorm/lite |

**Threshold para aplicar protocolo:** resposta com mais de 3 sentenças **OU** envolve código/arquivos **OU** há ambiguidade.

---

## 3. Modo Turbo — Busca Direta no Código

> Para perguntas do tipo "onde está X no código". Resultado: 3-5 tool calls, ~15-30s.
> Fórmula S tier validada: anchor-pattern + budget calibrado + self-consistency (2 termos de fallback).
> Ver experimentos completos em: `obsidian/vibefu_bench/thinking-lite/data.md`

**Quando usar:** "onde está", "qual arquivo", "qual rota", "qual função faz X" — qualquer localização de código.

**Protocolo OBRIGATÓRIO — S+++ tier (campeões: B4-V9 + SSS-V01 — 50-55k / 1 tool / 6.5-9.5s / completo — limite físico):**

```
[REGRA 0: VERIFY ANCHOR — OBRIGATÓRIO ANTES DE TUDO]
□ Path anchor existe? (ls <path_base> mentalmente)
□ Arquivo anchor dentro do path? (se possível, listar 1 arquivo esperado)
□ Termos fazem sentido para o anchor? (mentalizar estrutura)

Se algum falhar → NÃO fazer grep. ESCALATION direto.
  Exemplo: se anchor é "apps/bo/handlers/" mas procuro em "apps/front/",
  não pedir grep — avise: "Caminho provável é X. Arquivo pode estar em Y."
```

```
[REGRA 1: ANCHOR MAP ANTES DO GREP]
Declarar onde cada tipo de artefato vive (veja tabela abaixo).

[REGRA 2: GREP COM TODOS OS TERMOS SIMULTÂNEOS]
Grep "<termo1>\|<termo2>\|<termo3>\|<termo4>" em <path_base>/

→ Um único grep com todos os nomes simultaneamente retorna
  arquivos e linhas de todos os itens de uma vez.
→ Com resultado em mãos, responder sem tool calls adicionais.

[REGRA 3: FALLBACK CADEIA PREDEFINIDA]
Call 1: Grep "<termo_original>"
Call 2: Grep "<termo_snake_case>"     (se original era camelCase)
Call 3: Grep "<termo_camelCase>"      (se original era snake_case)

Depois de 3 calls vazios → ESCALATION. NÃO explorar pastas.
Razão: V02 caiu em loop 43 calls. Fallback ordenado = max 3.

[REGRA 4: TIMEOUT HEURÍSTICO — STOP SEARCHING]
Se 3 calls consecutivos retornam vazio:
  → PARE. Não significa fracasso — significa "não em anchor esperado".
  → Responder com honestidade:
     "Procurei em <anchor>. Se não encontrado, arquivo pode estar em:
      <alternativa1>, <alternativa2>. Recomendação: escalate para Sonnet."

Isso previne V06 (F tier — path não encontrado) e V02 loops.
```

**Quando usar cada modo:**

| Situação | Protocolo | Calls |
|----------|-----------|------:|
| Termos conhecidos, path base conhecido | Grep multi-termo `\|` | **1** |
| Valor exato desconhecido (constante string) | Read arquivo específico | 1 |
| 4+ itens de localização distintos | Grep `\|` combina tudo | **1** |
| Arquivos conhecidos com linhas prováveis | Read com offset+limit | 1-2 |
| Localização incerta | Grep + Read confirmatório | 2-3 |

**Fórmula 1-call (S+++ tier):**
```
Grep "FuncA\|FuncB\|FuncC\|constD" em /path/base/
→ resultado tem arquivo:linha de cada termo
→ responder direto com os dados
```

**Ordem de Fallback (previne V02 loop infinito):**

| Call | Tática | Exemplo | Quando |
|------|--------|---------|--------|
| 1 | Grep termo original | `"HandleDashboard"` | Sempre |
| 2 | Snake_case | `"handle_dashboard"` | Se call 1 vazio |
| 3 | CamelCase alternativo | `"handleDashboard"` | Se calls 1-2 vazios |
| 4+ | **STOP** → ESCALATION | — | Nunca continuar além de 3 |

**Nota:** B4-V9 atingiu o limite físico (1 tool = mínimo possível para busca em codebase desconhecido). Fallback cadeia reduz casos de loop: V02 tinha 43 calls (F tier), fallback = max 3-4.

**Mapa de anchor por tipo de artefato (monolito Estratégia):**

| Tipo | Anchor path |
|------|-------------|
| Handler HTTP | `apps/bo/internal/handlers/` |
| Service | `apps/pagamento_professores/internal/services/` |
| Worker/SQS | `apps/bo/internal/handlers/dashboard/` |
| Permissão | `apps/bo/internal/handlers/common/permissions.go` |
| Rota registrada | `apps/bo/internal/handlers/container.go` |
| Struct/Request | `apps/pagamento_professores/structs/` |

**Regras:**
- Declarar ANCHOR + BUDGET + OPÇÕES antes de qualquer tool call
- Nunca explorar pastas — grep sempre com termo
- Se Call 1 vazio → tentar fallback (não explorar)
- Budget esgotado → responder com o que tem, sinalizar lacuna honestamente
- Se exceder budget × 2 → ESCALATION

**Exemplo:**
```
ANCHOR: apps/bo/internal/handlers/dashboard/
BUDGET: 5 calls (3 problemas × 1.5)
OPÇÕES: "BulkGenerateSnapshot" | "bulk_generate_snapshot"

Call 1: Grep "BulkGenerateSnapshot" no anchor
Call 2: Grep "BulkGenerateSnapshot" em container.go
→ Resposta com arquivo:linha + rota HTTP
```

---

## Experimentos — Técnicas Testadas

> Seção de rastreabilidade. Cada técnica tem tier validado em benchmark real.
> Benchmark: P1–P4 (localização no monolito Estratégia) | Modelo: Haiku 4.5
> Dados completos: `/workspace/obsidian/vibefu/sss_bench/` (20 variações + dashboard)

| ID | Técnica | Tier | Tokens | Tools | Completo | Descrição |
|----|---------|:----:|-------:|------:|:--------:|-----------|
| `budget-quality` | Budget calibrado (N×1.5) | **S** | 58.5k | 5 | ⚠️ | Budget explícito força planejamento antes de agir |
| `anchor-pattern` | Mapa de paths por tipo | **S** | 73.5k | 14 | ✅ | Elimina exploração — agente sabe onde olhar |
| `self-consistency` | 2 termos antes do grep | **S** | 67.0k | 19 | ✅ | Fallback cognitivo, elimina retrabalho pós-falha |
| `sub-questions` | Decomposição em 2 sub-perguntas | A | 72.9k | 21 | ✅ | Força clareza mas não reduz tool calls |
| `budget-3-strict` | Budget fixo (3 calls) | A | 67.9k | 7 | ⚠️ | Rápido mas muito apertado para multi-problema |
| `format-output-first` | Template de saída antes da busca | B | 71.4k | 25 | ✅ | Organiza output, não reduz esforço |
| `step-back-hypothesis` | Hipótese declarada antes | B | 75.1k | 20 | ✅ | Overhead acumulado em multi-problema |
| `minimal-3rules` | 3 regras sem path anchor | C | 68.9k | 27 | ❌ | **Alucina** sem âncora de path |
| `cascade-triple` | Budget+grep+path combinados | C | 70.3k | 30 | ✅ | Múltiplas regras = desorientação |
| `grep-path-anchor` | Grep-first sem budget | **F** | 83.4k | 43 | ✅ | Anti-padrão: loops de busca sem planejamento |

**Batch 2 — fórmulas refinadas:**

| ID | Técnica | Tier | Tokens | Tools | Tempo | Completo | Notas |
|----|---------|:----:|-------:|------:|------:|:--------:|-------|
| **SSS-V01** | **anchor + multigrep 4 termos** | **S+++** | **55.2k** | **1** | **9.5s** | ✅ | **NOVO CAMPEÃO SSS — Batch confirmou B4-V9** |
| **SSS-V16** | **expertise + 1 call verify** | **S+** | **54.3k** | **4** | **6.0s** | ✅ | **Expertise bem calibrada com verificação** |
| `multigrep-1call` | grep 4 termos simultâneos `\|` | **S+++** | 50.9k | 1 | 6.5s | ✅ | B4-V9 (Batch 4) — mantém recorde histórico |
| `calls-pre-planejados` | plano completo antes de executar | **S++** | 52.8k | 3 | 9s | ✅ | Batch 3 — usar só com anchor calibrado |
| `expertise-injection` | conhecimento do codebase injetado | **S+** | 55.5k | 9 | 19s | ✅ | Robusto mas exige verificação (V16 confirmou) |
| `anchor-budget` | anchor+budget sem opções | S | 56.5k | 8 | 26s | ⚠️ | P4 parcial — requer fallback |
| `anchor-file` | path de arquivo exato | S | 62.8k | 11 | 25s | ✅ | Simples e robusto quando path é fixo |
| **SSS-V05** | **sparse-read + anchor (RISCO)** | **S++** | **51.8k** | **4** | **5.1s** | ❌ | **Mais rápido MAS P2 linha errada — sparse offset impreciso** |
| `budget-self-consistency` | budget+2 opções sem anchor | B | 64.8k | 13 | 41s | ⚠️ | **Aluciou P2** sem anchor (V06, V14 confirmaram) |

**Regra derivada dos experimentos (SSS Batch confirmou):**
- 1 técnica isolada > 3 técnicas combinadas (V01, V05 confirmaram)
- Budget sem anchor = incompleto; anchor sem budget = lento mas completo
- Minimalismo sem path anchor → hallucination (V14 aluciou, V06 falhou)
- Sparse-read com offset impreciso = linha errada (V05 P2 errou linha 6 vs 12)
- Expertise sem verificação = confiança falsa (V16 adicionou 1 call de verificação = S+)

---

## Armadilhas Comuns — Baseado em Falhas SSS (V14, V06, V08, V12)

| Armadilha | Sintoma | Lição |
|-----------|---------|-------|
| **Sparse-read sem offset calibrado** | Retorna linha errada | V05 tentou otimizar — resultado: P2 linha 6 em vez de 12. Use `Grep` em vez disso. |
| **Expertise conflitante** | Label confunde posição no path | V08 e V12 nomearam "expertise" mas o modelo confundiu handlers de diferentes apps. Separar por anchor claro. |
| **Múltiplas técnicas (4+)** | Desorientação, hallucination | V17 combinou: anchor+plano+multigrep+fmt = 67.1k tokens, 9 tools, C tier. 1 técnica = S tier. |
| **Plano sem verificação** | Alucinação confiante | V14 e V06 planejaram mas não verificaram anchors com `ls` antes. AAV exige VERIFY. |
| **Grep sem budget** | Loops infinitos de busca | V02: grep-first sem planejamento = 83.4k tokens, 43 calls, F tier (pior tier). |

---

## 4. Modo Interativo — Chain of Draft (CoD)

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

Criar card em `projects/hermes/tasks/` com `model: sonnet` e descrição completa.

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
      ├── localização de código ────▶ Modo Turbo
      │                              Grep → Grep container → Read (max 4 calls)
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
