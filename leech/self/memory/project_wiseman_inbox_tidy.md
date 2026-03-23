---
name: wiseman-inbox-tidy
type: project
updated: 2026-03-23T00:20Z
---

# Wiseman — Modo INBOX_TIDY

Adicionado em 2026-03-23 à rotação do Wiseman: WEAVE → AUDIT → META → CONSOLIDATE → **INBOX_TIDY** → ENFORCE → WEAVE

## O que faz
Organiza arquivos soltos em `inbox/` agrupando por assunto em subpastas.

## Regras críticas
- **Só age com 3+ arquivos** sobre o mesmo tema — menos que isso: deixa como está
- Nunca move `feed.md` nem arquivos com prefixo `ALERTA_`
- Nunca toca pastas já existentes
- Cria `inbox/<slug-tema>/RESUMO.md` com tabela dos arquivos + narrativa do que aconteceu

## Formato RESUMO.md
Frontmatter: `criado_por: wiseman`, `em:`, `assunto:`, `arquivos: N`
Corpo: parágrafo narrativo + tabela de arquivos com resumo de uma linha cada

**Fonte:** `self/agents/wiseman/agent.md` modo INBOX_TIDY
