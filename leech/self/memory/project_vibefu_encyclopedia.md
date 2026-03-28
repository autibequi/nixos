---
name: project_vibefu_encyclopedia
description: Enciclopédia VibeFu em obsidian/vibefu/ — 105 técnicas de vibecoding rankeadas, com índice e stats
type: project
---

# VibeFu — Enciclopédia de Vibecoding

**Path:** `/workspace/obsidian/vibefu/`
**Criado:** 2026-03-26

## O que é
Enciclopédia com 105 técnicas, ferramentas e padrões para desenvolvimento assistido por IA, organizadas em 14 categorias (spec, testing, security, review, agent, pattern, prompt, ide, fullstack, dsl, memory, cicd, methodology, benchmark, guardrails).

## Estrutura
- `_INDEX.md` — índice com tabelas por categoria e [[wikilinks]]
- `_RANKING.md` — ranking 0-1000 com justificativa para cada técnica
- `_STATS.md` — estatísticas de mercado e tendências
- `<categoria>-<nome>.md` — 105 arquivos individuais com frontmatter padronizado

## Template por arquivo
Frontmatter: name, category, maturity, url, tags
Seções: O que é, Como funciona, Quando usar, Prós e Contras, Integração com Vibecoding, Links

## Top 5 do ranking
1. ide-claude-md (980) — instruções persistentes
2. prompt-decomposition (970) — dividir antes de promtar
3. ide-cursor-rules (960) — system prompt por projeto
4. memory-context-engineering (950) — gerenciamento de contexto
5. prompt-self-review (940) — LLM revisando próprio output

**Why:** Pedro quer referência prática para vibecoding de elite, não teoria.
**How to apply:** Consultar quando surgir discussão sobre ferramentas AI, spec-driven dev, ou melhoria de workflow.
