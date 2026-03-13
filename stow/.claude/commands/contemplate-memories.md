# Contemplar Memórias

Introspecção profunda: analisar conversas recentes, extrair aprendizados, e evoluir memórias + personalidade + habilidades.

## Processo

### 1. Ler estado atual (obrigatório)
- `vault/kanban.md` — estado do trabalho
- `vault/scheduled.md` — tasks recorrentes
- Todos os `memory/*.md` — memórias atuais
- `/workspace/CLAUDE.md` — personalidade
- `stow/.claude/commands/` — commands existentes
- Listar `stow/.claude/skills/` — skills existentes (não precisa ler tudo, só a estrutura)

### 2. Minerar transcripts recentes
Buscar nos `.jsonl` em `~/.claude/projects/-workspace/` (ordenar por data, focar nos mais recentes).

**Buscar por categoria:**

| Categoria | Termos de busca |
|-----------|----------------|
| Correções | "não faça", "para de", "errado", "ao invés", "não quero" |
| Preferências | "prefiro", "sempre", "nunca", "gosto", "quero que" |
| Info user | "eu trabalho", "meu papel", "sou", "minha equipe" |
| Projetos | nomes de projetos do kanban, "deadline", "sprint", "release" |
| Pedidos explícitos | "lembra", "memoriza", "anota", "grava" |
| Frustração | "de novo", "já disse", "repete", "toda vez" |

```
Grep pattern="<termo>" path="~/.claude/projects/-workspace/" glob="*.jsonl"
```

**Dica**: usar Agent haiku pra paralelizar buscas em múltiplos transcripts.

### 3. Classificar e decidir destino

Para cada achado, decidir:

| Achado | Destino | Critério |
|--------|---------|----------|
| Feedback/correção do user | `memory/feedback_*.md` | Aplicável a futuras sessões |
| Info sobre o user | `memory/user_*.md` | Ajuda a personalizar interações |
| Contexto de projeto | `memory/project_*.md` | Estado/decisão que afeta trabalho futuro |
| Referência externa | `memory/reference_*.md` | Ponteiro pra onde encontrar info |
| Regra fundamental | `CLAUDE.md` | Afeta TODAS as sessões e agents |
| Habilidade nova/melhorada | `stow/.claude/commands/` ou `skills/` | Padrão reutilizável identificado |
| Lixo/efêmero | Ignorar | Contexto de conversa única |

### 4. Atualizar memórias
- **Existentes**: atualizar conteúdo se evoluiu, remover se obsoleto
- **Novas**: criar arquivo com frontmatter correto + adicionar ao `MEMORY.md`
- **Formato obrigatório**:
```markdown
---
name: tipo_topico
description: uma linha específica — usada pra decidir relevância
type: user|feedback|project|reference
---

Conteúdo conciso.

**Why:** motivo/contexto
**How to apply:** quando/como usar
```

### 5. Evoluir personalidade (CLAUDE.md)
Perguntar pra cada achado relevante:
- "Isso é uma regra que afeta TODAS as sessões?" → CLAUDE.md
- "Isso é específico de um projeto/contexto?" → memory/
- "Isso é um padrão reutilizável?" → command ou skill

**Ao editar CLAUDE.md**: manter conciso, não duplicar o que já está lá, respeitar a estrutura existente.

### 6. Evoluir habilidades
Identificar se algum achado sugere:
- **Novo command**: padrão que o user pediu mais de uma vez (ex: "faz um resumo de X")
- **Melhoria em command existente**: passo faltando, instrução ambígua
- **Nova skill ou template**: padrão de código/workflow recorrente nos projetos
- **Melhoria em skill existente**: caso de borda, regra de negócio aprendida

Ao criar/editar, seguir a estrutura existente em `stow/.claude/`.

### 7. Limpar kanban
- Remover cards duplicados (mesmo item em Backlog e Concluído)
- Verificar se cards em "Em Andamento" ainda são válidos
- Garantir que cards concluídos têm link pro resultado

### 8. Reportar
Resumo estruturado:

```
## Contemplação — YYYY-MM-DD

### Memórias
- Criadas: [lista]
- Atualizadas: [lista]
- Removidas: [lista]

### Personalidade (CLAUDE.md)
- [alterações ou "sem alterações"]

### Habilidades
- Commands: [criados/atualizados]
- Skills: [criadas/atualizadas]

### Kanban
- [limpezas feitas]

### Insights
- [observações que não viraram ação mas valem registrar]
```

## Regras

- NÃO salvar coisas deriváveis do código ou git history
- NÃO duplicar o que já está em CLAUDE.md
- NÃO salvar contexto de conversa única (efêmero)
- Converter datas relativas pra absolutas ("amanhã" → "2026-03-14")
- Ser conciso — memórias longas não são lidas
- Priorizar feedback do user sobre inferências próprias
- Usar Agent haiku pra buscas pesadas em transcripts
- SEMPRE verificar se já existe memória/command/skill antes de criar novo — atualizar > duplicar
