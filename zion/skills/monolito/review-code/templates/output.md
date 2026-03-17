# Template de Output — Code Review

## Pasta de artefatos

```
obsidian/artefacts/<nome-review>/
├── README.md
├── 01-visao-geral.md
├── 02-code-review.md
└── 03-topicos-discussao.md
```

---

## README.md

```markdown
---
task: <nome-review>
pr: "#<number>"
author: <github-username>
branch: <branch-name>
date: YYYY-MM-DD
status: done
---

# Code Review — PR #<N>: <Título>

<1-2 frases descrevendo o PR>

## Índice

- [01 - Visão Geral](01-visao-geral.md) — arquitetura, tabelas novas, fluxo
- [02 - Code Review](02-code-review.md) — análise técnica, pontos de atenção
- [03 - Tópicos de Discussão](03-topicos-discussao.md) — perguntas e temas de debate
```

---

## 01-visao-geral.md

Estrutura:

1. **Resumo Executivo** (3-5 frases)
2. **Motivação** — por que essa mudança existe
3. **Arquitetura** — diagrama ASCII ou descrição do fluxo principal
4. **Tabelas/Migrations novas** — tabela com nome, migration, propósito
5. **Entities novas** — tabela com nome, arquivo
6. **Repositories novos** — tabela com nome e operações
7. **Services novos** — tabela com nome e propósito
8. **Libs novas** — se houver
9. **Refactors colaterais** — mudanças que não são o core mas são relevantes

---

## 02-code-review.md

Estrutura:

1. **Qualidade Geral** (1 parágrafo — positivo, negativo, ou misto)
2. **Análise por Área** — uma seção por componente, cada uma com:
   - **Positivo:** o que está bem feito
   - **Ponto de atenção:** problemas encontrados com código inline
3. **Resumo de Pontos de Atenção** — tabela final:

```markdown
| # | Severidade | Descrição |
|---|-----------|-----------|
| 1 | **Blocker** | Descrição do problema |
| 2 | Média | Descrição |
| 3 | Baixa | Descrição |
| 4 | Info | Observação |
```

---

## 03-topicos-discussao.md

Estrutura:

Seções numeradas, cada uma com:
- **Título** como pergunta ou observação
- **Contexto** — por que estou levantando isso
- **Pergunta** — pergunta direta pro autor
- (Opcional) **Subpergunta** — follow-up

Finalizar com tabela:

```markdown
## Resumo: O que é blocker vs nice-to-have

| Tópico | Prioridade |
|--------|-----------|
| Nil check em X (#N do code review) | **Blocker** |
| Thread-safety de Y (#N) | **Verificar** |
| Testes pra Z (#N) | Nice-to-have |
```

---

## Frontmatter obrigatório em todos os artefatos

```yaml
---
task: <nome-review>
date: YYYY-MM-DD
type: visao-geral | code-review | topicos-discussao
---
```
