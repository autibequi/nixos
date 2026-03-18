# Ler Card Jira

Le um card Jira da Estrategia com TODOS os campos relevantes e apresenta de forma estruturada.

## Entrada
- `$ARGUMENTS`: numero do card Jira (ex: FUK2-12090)

## Instruções

Ler a skill `estrategia/jira` em `~/.claude/skills/estrategia/jira/SKILL.md` e seguir os passos documentados.

### Resumo rápido (a skill tem detalhes completos):

1. Chamar `getJiraIssue` com:
   - `cloudId`: `9795b90e-d410-4737-a422-a7c15f9eadf0`
   - `issueIdOrKey`: `$ARGUMENTS`
   - `fields`: `["*all"]`
   - `expand`: `"names"`
   - `responseContentFormat`: `"markdown"`

2. Resultado será salvo em arquivo (>70K chars). Usar `jq` para extrair:
   - Campos padrão: summary, status, priority, assignee, labels, comments, attachments
   - Campos Tech: Sugestão de Implementação (`customfield_11246`), DoD Engenharia (`customfield_11258`), Horizontal (`customfield_11263`), Frente de Produto (`customfield_11266`), Estimativa (`customfield_11322`), etc.
   - Texto de campos ADF: extrair recursivamente com script python

3. Apresentar ao usuario de forma estruturada:
   - Header: ID, titulo, tipo, status, prioridade, assignee
   - Descricao (markdown)
   - Sugestao de Implementacao (se preenchida)
   - DoD Engenharia (se preenchida)
   - Metadados Tech
   - Comentarios relevantes (ignorar automacoes)
   - Links e sub-tasks
