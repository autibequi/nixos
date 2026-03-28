---
name: feedback_go_inspector
description: Lições da primeira execução do go-inspector no monolito — como spawnar inspetores, estrutura de artefatos, armadilhas de delegação
type: feedback
---

## Regra 1: Não delegar o go-inspector para o agente Monolito

O agente Monolito não consegue spawnar sub-agentes em background — ao tentar executar o skill go-inspector dentro dele, o agente executa tudo sequencialmente em vez de 6 inspetores paralelos.

**Why:** O Agent tool não está disponível dentro de subagentes (só no contexto principal do Claude Code).

**How to apply:** Ao invocar `estrategia:mono:go-inspector`, o orquestrador (Claude Code principal) deve spawnar os 6 inspetores diretamente como `Agent subagent_type=general-purpose run_in_background=true`, não delegar para um agente Monolito fazer isso.

---

## Regra 2: SKILL.md do go-inspector usa path de skills errado

O SKILL.md (`/home/claude/.claude/skills/monolito/go-inspector/SKILL.md`) existe, mas o registry de skills da estratégia aponta para `estrategia/mono/go-inspector`. Quando o Skill tool é invocado com `estrategia:mono:go-inspector`, ele funciona. O problema é a delegação interna ao agente Monolito.

**Why:** O agente Monolito recebe o texto do skill expandido mas não tem o Agent tool disponível para spawnar sub-agentes.

**How to apply:** Executar o go-inspector diretamente no contexto principal. Se precisar delegar, passar o diff e contexto explicitamente no prompt e pedir análise consolidada (não paralela).

---

## Regra 3: Artefatos de inspeção vão em `/workspace/obsidian/inspection/<slug>/<data>/`

O diretório `/workspace/obsidian/inspection/` não existia na primeira execução — foi criado manualmente. O INDEX.md também não existia.

**Why:** Primeira execução do sistema.

**How to apply:** Sempre verificar se o diretório existe antes de tentar escrever. Criar com `mkdir -p` se necessário. INDEX.md deve ser criado se não existir.

---

## Regra 4: inspector-claude.md já tinha aprendizados pré-populados da própria inspeção

O agente Monolito, ao executar manualmente, já atualizou o `inspector-claude.md` com 4 aprendizados novos (AuditLog fora de transação, erro silenciado com `_`, cache unmarshal nil, goroutine manual vs helper). Isso significa que a auto-evolução dos inspetores funcionou mesmo sem o fluxo paralelo formal.

**How to apply:** Após cada inspeção, verificar se os arquivos `.md` dos inspetores em `/workspace/obsidian/bedrooms/inspectors/` foram atualizados. Se não, adicionar manualmente os aprendizados relevantes.
