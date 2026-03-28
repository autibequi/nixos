---
name: feedback_present_plan_before_bulk_ops
description: Apresentar plano explícito antes de executar operações em lote em self/ — renomear, criar, remover múltiplos arquivos
type: feedback
---

Antes de executar qualquer operação que afete múltiplos arquivos do sistema (renomear docs core, remover arquivos, mesclar conteúdo de vários arquivos), SEMPRE apresentar tabela com o plano antes de agir.

**Why:** Em sessão 2026-03-28, fui executar consolidação dos docs core (renomear agent.md→AGENT.md, PERSONALITY.md→PERSONA.md, remover INIT.md/RULES.md/GLOSSARY.md) direto, sem mostrar o plano. Usuário interrompeu: "me diz antes de fazer".

**How to apply:**
- Operações de 1 arquivo simples: ok executar direto
- 2+ arquivos afetados OU remoção OU renomear: mostrar tabela `| Arquivo | Ação | Destino |` e aguardar confirmação
- Isso se aplica especialmente a `self/` (sistema core), não é necessário para código de projeto normal
