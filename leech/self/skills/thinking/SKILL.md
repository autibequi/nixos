---
name: thinking
description: Entrypoint universal para qualquer problema — dispatcher que roteia para investigate, brainstorm, refine ou code/debug conforme o tipo. Nunca sair fazendo sem entender primeiro.
---

# thinking — Entrypoint Universal

> Todo problema entra aqui. thinking orquestra o pipeline certo para cada situação.

## Dispatcher — tipo de problema → ação

| Tipo de problema | Ação |
|---|---|
| Qualquer coisa | **Sempre começar por `thinking/investigate`** (coletar dados antes de pensar) |
| Feature / card Jira | Fluxo thinking (passos 1-7) → `thinking/refine` — ler card com `coruja/jira` |
| Bug / stack trace | → `code/debug` |
| Pedido vago | Clarificar → rotear |
| Análise de código | → `code/analysis` |
| Preso / loop / sem causa clara | → `thinking/brainstorm` (automático) |

## Sub-skills

| Arquivo | Quando usar |
|---|---|
| `investigate` | **Sempre primeiro** — coletar logs, código, relatos, histórico |
| `brainstorm` | Quando preso ou em loop — gerar e validar teorias |
| `refine` | Quebrar feature/spec em tasks atomicas ordenadas por camada |

---

## Pipeline completo

```
Problema chega
        │
        ▼
[0] investigate          — coletar logs, código, relatos, histórico
        │                   (thinking/investigate — SEMPRE primeiro)
        ▼
[1] Ler e entender       — Jira card, spec, descricao do usuario
        │
        ▼
[2] Investigar codebase  — padroes existentes, camadas, pontos de extensao
        │
        ▼
[3] Mapear               — dependencias, riscos, decisoes em aberto
        │
        ├─── preso? loop? ──▶ [brainstorm] — gerar e validar teorias
        │                      (thinking/brainstorm — automático)
        ▼
[4] Apresentar           — visual via meta:art (ASCII ou Chrome)
        │
        ▼
[5] Validar              — usuario aprova, ajusta, ou rejeita
        │
        ├─── é bug com causa clara? ──▶ code/debug → fix
        │
        ▼
[6] Refinar tasks        — invocar thinking/refine → backlog atomico
        │
        ▼
[7] Implementar          — so apos aprovacao explicita
```

---

## Passo 1 — Ler o problema

Se vier como card Jira: invocar `estrategia/jira` para extrair todos os campos.

Se vier como descricao livre: extrair:
- **O que** deve ser feito (funcionalidade)
- **Por que** (motivacao/contexto de negocio)
- **Criterios de aceite** (como saber que esta pronto)
- **O que esta fora do escopo** (explicitamente)

---

## Passo 2 — Investigar o codebase

Nao planejar sem investigar. Busca em 3 ondas:

**Onda 1 — Mapa geral:**
```bash
# Estrutura de pastas
# Arquivos de entrada (main, app, schema, rotas)
# Dependencias declaradas (go.mod, package.json, pubspec.yaml)
```

**Onda 2 — Padroes existentes:**
- 1 entidade/struct existente → naming e estrutura
- 1 repositorio/service existente → padrao de acesso
- 1 handler/component existente → padrao de UI ou API

**Onda 3 — Pontos de extensao:**
- Onde registrar o novo componente (DI container, main, router)
- Existe algo similar ja implementado?
- Quais interfaces precisam mudar?

---

## Passo 3 — Mapear dependencias e riscos

Identificar antes de criar tasks:

| Item | Perguntas |
|---|---|
| **Camadas** | Quantas camadas tocam? Qual a ordem de dependencia? |
| **Riscos** | O que pode dar errado? Quais decisoes tecnicas em aberto? |
| **Ambiguidades** | O que a spec nao define? Precisa de input do usuario agora? |
| **Impacto** | O que pode quebrar? Tem testes existentes? |

---

## Passo 4 — Apresentar visualmente via meta:holodeck

**Sempre apresentar antes de qualquer implementacao.**

Usar `meta:holodeck` — Mermaid flowchart com zoom/drag no Chrome.

### Formatos recomendados por tipo de problema

| Tipo de problema | Formato |
|---|---|
| Feature nova com multiplas camadas | Flowchart de camadas (handler→service→repo) |
| Bug / investigacao | Flowchart do handler com hipoteses marcadas por cor |
| Refactor | Sequence diagram antes/depois |
| Feature cross-repo | Sequence diagram entre servicos |

### O que o output deve conter

1. **Resumo do entendimento** — o que voce entendeu do problema (1 paragrafo)
2. **Mapa de impacto** — camadas/arquivos afetados (ASCII ou Mermaid)
3. **Decisoes em aberto** — o que precisa de validacao antes de prosseguir
4. **Proposta de tasks** — lista numerada com estimativa de esforco
5. **Riscos identificados** — o que pode complicar

---

## Passo 5 — Validar com o usuario

Apos apresentar, parar e esperar resposta explicita.

Perguntar:
- "Esse entendimento esta correto?"
- "Tem algo fora do escopo que incluí por engano?"
- "As decisoes em aberto — voce ja tem preferencia?"

**Nao avancar sem resposta.**

---

## Passo 6 — Refinar tasks (invocar thinking/refine)

Apos validacao, invocar `thinking/refine` para:
- Quebrar em tasks atomicas (cada uma max ~30min)
- Ordenar respeitando camadas de dependencia
- Formatar backlog com T01, T02... + tabela de progresso
- Identificar tasks paralelas

---

## Passo 7 — Implementar

So apos backlog aprovado. Seguir a ordem das tasks. Nao pular camadas.

---

## Gatilhos de uso

| Situacao | Acao |
|---|---|
| Card Jira recebido para implementar | **Obrigatorio** — pipeline completo (investigate → thinking → refine) |
| Feature com mais de 2 arquivos | **Obrigatorio** |
| Pedido vago ("faz um sistema de X") | **Obrigatorio** — clarificar antes de refinar |
| Bug / stack trace / log recebido | investigate → code/debug |
| Preso ou em loop de hipóteses | → `thinking/brainstorm` (automático) |
| Duvida sobre onde esta o problema | investigate primeiro, depois thinking |
| Hotfix urgente (<1 arquivo, causa clara) | Dispensavel — ir direto para code/debug |

> **Regra:** sempre que houver qualquer problema — começar por `thinking/investigate` para coletar dados. Depois pensar.

---

## Skills e ferramentas para investigacao

| Ferramenta / Skill | Quando usar |
|---|---|
| `code/debug` | Debugging sistematico (4 fases: reproduzir, hipoteses, isolar, verificar) |
| `coruja/grafana` | Metricas, latencia, erros em producao/staging |
| `coruja/opensearch` | Busca em logs centralizados por trace_id ou mensagem de erro |
| `coruja/jira` | Ler card, historico, comentarios, repro steps reportados |
| `coruja/glance` | Overview rapido do estado dos repos e servicos |
| `code/analysis` | Entender fluxo de codigo, dependencias entre camadas |
| `code/inspect` | Inspecionar arquivo/funcao especifica em detalhe |
| `thinking/refine` | Quebrar investigacao em tasks atomicas apos entender o problema |

**Comandos uteis:**
```bash
git log --oneline -20              # mudancas recentes
git diff HEAD~1                    # o que mudou no ultimo commit
git blame <arquivo>                # quem tocou qual linha quando
docker logs <container> --tail 100 # logs do container
grep -r "mensagem exata" /workspace/mnt/  # buscar ocorrencia no codigo
```

---

## Anti-patterns

| Errado | Certo |
|---|---|
| Sair implementando sem ler o card completo | Ler todos os campos Jira, inclusive comentarios |
| Apresentar so texto, sem visual | Sempre usar meta:holodeck — o visual facilita a validacao |
| Pedir validacao e avancar sem resposta | Parar. Esperar. Nao presumir aprovacao |
| Refinar sem investigar o codebase | Onda 1-2-3 primeiro, plano depois |
| Criar tasks grandes ("implementar o modulo X") | Cada task = 1 responsabilidade, resultado verificavel |
