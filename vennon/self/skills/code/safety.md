# /code:safety — Validation, Retry, Escalation Gates

Guardião do DevFlow que valida, reavalia, sabe quando parar, quando pedir ajuda.

## Responsabilidades

- [ ] **Validação de Saída**: Cada skill produz artefato válido?
- [ ] **Checkpoint Gates**: Antes de avançar fase, validar pré-requisitos
- [ ] **Retentativas Inteligentes**: Se falha, tentar estratégia alternativa
- [ ] **Escalação**: Quando ambiguidade/bloqueador permanente → pedir contexto/ajuda
- [ ] **Critérios de Falha**: Quando abandonar uma abordagem
- [ ] **Man-in-the-Middle**: Review gates antes de fases críticas

## Fluxo com Safety

```
/code:manager create FUK2-987213
  ↓
/code:refine FUK2-987213
  ↓ SAFETY CHECKPOINT
  ↓ ✓ REFINING preenchido com 5+ questões mapeadas?
  ↓ ✓ Scope definido (inclui/exclui)?
  ↓ ✓ Impacto identificado (quais repos)?
  ↓ SE NÃO: ESCALATE (user precisar esclarecer requisito)
  ↓ SE SIM: continua
  ↓
/code:guru FUK2-987213 (se complexo)
  ↓ SAFETY CHECKPOINT
  ↓ ✓ 3+ opções por questão?
  ↓ ✓ Prós/contras documentados?
  ↓ ✓ Recomendação clara?
  ↓ SE NÃO: RETRY com /brainstorm (nova rodada)
  ↓ SE SIM: continua
  ↓
/code:plan FUK2-987213
  ↓ SAFETY CHECKPOINT
  ↓ ✓ Subtasks (A/B/C/D) quebradas?
  ↓ ✓ Checkboxes mini (15-30 por subtask)?
  ↓ ✓ Ordem/dependências claras?
  ↓ SE NÃO: RETRY com Wiseman (validar quebra)
  ↓ SE SIM: REVIEW GATE (Manager aprova design)
  ↓
/code:develop FUK2-987213-A
  ↓ SAFETY CHECKPOINT (durante desenvolvimento)
  ↓ ✓ Checkpoint a cada 10 checkboxes
  ↓ ✓ Tests passando?
  ↓ ✓ Bugs encontrados < 3?
  ↓ SE 3+ BUGS: ESCALATE (Wiseman investiga padrão)
  ↓ SE SIM: continua
  ↓
/code:qa FUK2-987213
  ↓ SAFETY CHECKPOINT
  ↓ ✓ 80%+ testes passando?
  ↓ ✓ Bloqueadores resolvidos?
  ↓ ✓ Documentação completa?
  ↓ SE NÃO: RETRY ou ESCALATE
  ↓ SE SIM: REVIEW GATE (you aprova)
```

---

## 🔐 Validação por Fase

### REFINING Checkpoint

**Mínimo válido:**
- [ ] Requisito mapeado (1+ frase clara)
- [ ] Scope definido (inclui X, exclui Y)
- [ ] Impacto identificado (2+ repos afetados)
- [ ] 3+ unknowns/riscos listados
- [ ] Agente principal atribuído

**Se falha:**
- ❌ Requisito vago → ESCALATE: "User, qual exatamente o requisito?"
- ❌ Scope indefinido → ESCALATE: "Inclui ou exclui Z?"
- ❌ Impacto desconhecido → RETRY: Wanderer mapeia repos

---

### ATTENTION Checkpoint

**Mínimo válido:**
- [ ] 3+ questões de design
- [ ] 3+ opções por questão
- [ ] Prós/contras documentados
- [ ] Recomendação clara + reasoning
- [ ] Nenhuma contradição entre opções

**Se falha:**
- ❌ <3 opções → RETRY: Brainstorm novamente
- ❌ Recomendação confusa → ESCALATE: "Qual é a melhor opção?"
- ❌ Contradições → RETRY: Wiseman consolida

---

### PLANNING Checkpoint

**Mínimo válido:**
- [ ] 3-5 subtasks (A, B, C, D, E)
- [ ] 15-30 checkboxes por subtask
- [ ] Dependências claras (A → B → C ou paralelo)
- [ ] Nenhuma tarefa "vaga" ou "TBD"
- [ ] Timeline realista (days/sprints)

**Se falha:**
- ❌ Subtask vaga → RETRY: Coruja refina
- ❌ Dependências circulares → ESCALATE: "Como quebrar sem ciclo?"
- ❌ >5 subtasks → ESCALATE: "Muito complexo, quebra em épocas?"

**REVIEW GATE:**
- [ ] Manager aprova quebra
- [ ] Coruja valida (viável?)
- [ ] Wiseman valida (impacto sistêmico?)

---

### DEVELOPING Checkpoint (A Cada 10 Checkboxes)

**Mínimo válido:**
- [ ] 80%+ checkboxes têm status ("testado", "com bug X", etc)
- [ ] Bugs encontrados < 3
- [ ] Nenhum bug "desconhecido" (todos têm status)
- [ ] Tests passando (unit, integration, ou manual)

**Se falha:**
- ❌ Checkpoint em 0% → ESCALATE: "Travado? Precisa ajuda?"
- ❌ 3+ bugs → ESCALATE: Wiseman investiga padrão
- ❌ Teste falhando → RETRY: Wanderer debug
- ❌ Bloqueia 3h+ → ESCALATE: "Precisa context? Repensar?"

**Fallback strategies:**
1. Primeira tentativa falha → Tentar abordagem alternativa
2. Segunda falha → Chamar Wanderer pra debug
3. Terceira falha → Escalate pra Wiseman (padrão sistêmico?)
4. Quarta falha → Pedir ajuda (User ou Guru brainstorm novo)

---

### QA Checkpoint

**Mínimo válido:**
- [ ] 80%+ testes passando
- [ ] Bloqueadores (CRITICAL) resolvidos
- [ ] Problemas MÉDIO catalogados (com timing de fix)
- [ ] Documentação 90%+ completa

**Se falha:**
- ❌ <80% testes → RETRY: Implementação volta pra DEVELOPING
- ❌ CRITICAL bloqueador não resolvido → ESCALATE
- ❌ Tudo quebrado → ESCALATE: "Repensar design"

**REVIEW GATE:**
- [ ] You aprova (não é você, então pode voltar)
- [ ] Manager consolida bloqueadores

---

## 🔄 Retentativas Inteligentes

### Retry Strategy: 3 Tentativas, Escalate

| Tentativa | Estratégia | Contexto |
|-----------|-----------|---------|
| **1** | Mesmo agente, nova rodada | "Tente novamente com novo contexto" |
| **2** | Agente diferente | "Wanderer tenta debug, Wiseman tenta consolidar" |
| **3** | Escalate + Brainstorm | "Guru brainstorm alternativa" ou "User fornece contexto" |

### Exemplo: Retry em DEVELOPING

```
Coruja tentou implementar /auth/logout

TENTATIVA 1:
- Implementa (falha por X razão)
- Retry: Coruja tenta novo design

TENTATIVA 2:
- Falha novamente
- Retry: Wanderer debug, encontra root cause

TENTATIVA 3:
- Wanderer encontra: padrão não existe em codebase
- Escalate: Guru brainstorm novo padrão
- Resultado: Design alternativo aprovado

TENTATIVA 4:
- Coruja implementa novo design
- Sucesso ✅
```

---

## 🆘 Escalação: Quando Pedir Ajuda

### Critérios de Escalação

**IMEDIATA** (sem retry):
- ❌ Requisito ambíguo/conflitante
- ❌ Bloqueador externo (dependência fora do escopo)
- ❌ Falta de definição fundamental
- ❌ Decisão que afeta múltiplos projetos

**APÓS 3 RETRIES**:
- ❌ Problema persiste após 3 tentativas
- ❌ Padrão não existe em codebase
- ❌ Abordagem inviável (arquitetura quebra)

**APÓS 3H DE BLOQUEIO**:
- ❌ Task não avança
- ❌ Nenhuma estratégia funcionou
- ❌ Precisa input externo

### Escalation Path

```
Safety detecta bloqueador

1. GURU BRAINSTORM (Escalation Level 1)
   → Novo brainstorm de ideias
   → Se resolve: continua
   → Se não: Level 2

2. WISEMAN CONSOLIDATION (Escalation Level 2)
   → Analisa sistêmico
   → Propõe redesign
   → Se resolve: continua
   → Se não: Level 3

3. USER INPUT (Escalation Level 3)
   → "FUK2-987213 está bloqueado em [X]. Preciso:"
   → "1. Esclarecer se [questão]?"
   → "2. Ou repensar [design]?"
   → "3. Ou abandonar [abordagem]?"
```

---

## 🚫 Critérios de Falha (Quando Desistir)

### Red Flags que Indicam "Não Vai Dar"

| Flag | Indicador | Ação |
|------|-----------|------|
| **Requisito contraditório** | "Rápido E simples" vs "Full-featured" | ESCALATE: user escolhe prioridade |
| **Arquitetura quebra** | Design afeta 5+ sistemas | ESCALATE: repensar fundamentalmente |
| **Padrão não existe** | Codebase nunca fez assim | ESCALATE: Guru brainstorm alternativa |
| **Bloqueador externo** | Depende de team X entregar | ESCALATE: reordenar tasks |
| **3+ abordagens falharam** | Tentou 3 estratégias, todas falham | ESCALATE: design fundamentalmente errado? |
| **3h+ bloqueado** | Task não avança | ESCALATE: user redefine scope |

### Exemplo: Quando Desistir

```
FUK2-987213: "Implementar JWT sem mudar banco de dados"

TENTATIVA 1: JWT com session tokens em Redis
  → Falha: não há Redis disponível

TENTATIVA 2: JWT puro (sem state)
  → Falha: logout precisa revoke, sem state é impossível

TENTATIVA 3: JWT com arquivo local de revokes
  → Falha: não escala multi-server

RED FLAG: "Sem mudar BD" é o bloqueador fundamental

ESCALATE: "Requisito pede JWT sem BD, mas isso é inviável.
Opções:
1. Aceitar mudar BD (add revoke table)
2. Aceitar logout não-imediato (apenas TTL)
3. Redesign completamente (não fazer JWT)"

USER CHOOSE → continua
```

---

## 📋 Safety Checklist por Skill

### /code:refine Safety

```
POST REFINING:
- [ ] Requisito é claro (não vago)?
- [ ] Scope definido (inclui/exclui 5+ coisas)?
- [ ] Impacto mapeado (repos, services)?
- [ ] 3+ risks/unknowns?
- [ ] Agente principal atribuído?

SE NÃO:
→ ESCALATE com questão específica

SE SIM:
→ APPROVE (Manager atualiza dashboard)
```

### /code:guru Safety

```
POST ATTENTION:
- [ ] 3+ opções por questão?
- [ ] Prós/contras documentados?
- [ ] Recomendação clara?
- [ ] Nenhuma contradição?
- [ ] Reasoning faz sentido?

SE NÃO:
→ RETRY (brainstorm nova rodada)
→ SE FALHA: ESCALATE "Qual opção é melhor?"

SE SIM:
→ APPROVE (Manager atualiza)
```

### /code:plan Safety

```
POST PLANNING:
- [ ] 3-5 subtasks?
- [ ] 15-30 checkboxes cada?
- [ ] Dependências claras?
- [ ] Nenhuma "vaga" (TBD)?
- [ ] Timeline realista?

SE NÃO:
→ RETRY (refinar, consultar Wiseman)

SE SIM:
→ REVIEW GATE (Manager + Coruja + Wiseman aprovam)
→ SE TODOS APROVAM: continua
→ SE ALGUÉM REJEITA: fix + retry
```

### /code:develop Safety

```
A CADA 10 CHECKBOXES:
- [ ] 80%+ checkboxes têm status?
- [ ] Bugs < 3?
- [ ] Tests passando?
- [ ] Nenhum bug "desconhecido"?

SE NÃO:
→ ESCALATE (travado?)

SE SIM:
→ Continua para próximos 10

FINAL (100%):
- [ ] Tudo [x]?
- [ ] Bugs: 0 ou documentados?
- [ ] Unit tests: OK?

→ READY pra QA
```

### /code:qa Safety

```
POST QA:
- [ ] 80%+ testes passando?
- [ ] CRITICAL bloqueadores = 0?
- [ ] MÉDIO bloqueadores catalogados?
- [ ] Documentação 90%?

SE NÃO:
→ RETRY (volta DEVELOPING)
→ SE 3+ RETRIES: ESCALATE

SE SIM:
→ REVIEW GATE (you aprova)
→ SE APROVA: WAITING
→ SE NÃO: fix + retry
```

---

## 🤝 Man-in-the-Middle: Review Gates

Antes de avançar fase crítica, **alguém humano/agente revisa**:

| Antes de | Reviewers | O que validar |
|----------|-----------|---------------|
| ATTENTION → PLANNING | Manager + Coruja + Wiseman | Design sound? Viável? Impacto ok? |
| PLANNING → DEVELOPING | Manager | Subtasks breakdown ok? |
| DEVELOPING → QA | Manager | 100% implementado? Tudo testado? |
| QA → WAITING | You (user) | Aprova?  ou volta? |
| WAITING → DONE | DevOps + You | Pode fazer deploy? |

---

## 📊 Safety Dashboard (Manager)

Manager mantém visível:

```
FUK2-987213 — Safety Status

| Fase | Checkpoint | Status | Retries | Escalations |
|------|-----------|--------|---------|-------------|
| REFINING | ✓ | PASS | 0 | 0 |
| ATTENTION | ✓ | PASS | 1 | 0 |
| PLANNING | ✓ | PASS (reviewers ok) | 0 | 0 |
| DEVELOPING | ⚠️ | IN PROGRESS | 2 bugs found | 0 |
| QA | ⏳ | AWAITING | — | — |

Próximo checkpoint: DEVELOPING @90% (10 checkboxes)
```

---

## Checklist: Safety Sistema Robusto

- [ ] Checkpoints definidos por fase
- [ ] Critérios de falha claros
- [ ] Retry strategy (3 tentativas, escalate)
- [ ] Escalation path (Guru → Wiseman → User)
- [ ] Man-in-the-middle gates (review antes críticas)
- [ ] Safety dashboard atualizado real-time
- [ ] Ninguém fica "travado" >3h sem escalate
- [ ] Cada skill sabe quando desistir e pedir ajuda
