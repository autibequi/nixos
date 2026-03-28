---
name: meta:rules:bedrooms
description: "Regras de estrutura do bedroom de cada agente — pastas permitidas, organizacao obrigatoria."
maintainer: wiseman
updated: 2026-03-24T22:00Z
---

# Bedrooms — Regras do Quarto

> Cada bedroom tem o nome do seu agente. `bedrooms/<nome>/` e territorio exclusivo desse agente.
> Este arquivo e lei obrigatoria — lido no boot junto com RULES.md.

---

## Estrutura Permitida

```
bedrooms/<nome>/
  memory.md                      <- raiz, obrigatorio. Atualizar ANTES de reagendar (Lei 2).
  done/                          <- SISTEMA. Runner coloca cards aqui. Agente NAO toca.
  DIARIO/<ANO>/<MES>.md         <- logs mensais  ex: DIARIO/2026/03.md
  DESKTOP/<tarefa>/              <- artefatos ativos, trabalho em andamento
  ARCHIVE/<tarefa>/              <- concluidos, cartas ao CTO, legado preservado
```

---

## Regras Obrigatorias

**1. Pastas permitidas (e so estas):**
- `DIARIO/` — logs do agente organizados por ano e mes
- `DESKTOP/` — trabalho ativo, artefatos em andamento
- `ARCHIVE/` — tudo que foi concluido, arquivado ou preservado

**Nenhuma outra pasta e permitida.** Pastas antigas (diarios/, outputs/, cartas/) devem ser migradas para ARCHIVE.

**2. Regras do DIARIO:**
- Estrutura: `DIARIO/<ANO>/<MES>.md` — apenas subpastas de ano, apenas arquivos de mes
- Exemplos validos: `DIARIO/2026/03.md`, `DIARIO/2026/04.md`
- Exemplos invalidos: `DIARIO/ciclo-hoje.md`, `DIARIO/2026/marco-detalhado.md`
- Formato de entrada (append-only): `## YYYY-MM-DD HH:MM UTC — <modo>\n<conteudo>`

**3. Regras do DESKTOP:**
- Livre para qualquer subtarefa ou artefato ativo
- Limpar periodicamente: o que nao e mais ativo vai para ARCHIVE
- Exemplo: `DESKTOP/proposta-worktree-auth/`, `DESKTOP/persona.md`, `DESKTOP/analise-hotspots.md`

**4. Regras do ARCHIVE:**
- Substitui diarios/, outputs/, cartas/ e done/ legados do agente
- Nao deletar conteudo arquivado — apenas mover para ARCHIVE
- Exemplo: `ARCHIVE/2026-03-carta-cto.md`, `ARCHIVE/ciclos-antigos/`

**5. Sobre memory.md:**
- Fica sempre na raiz do bedroom (`bedrooms/<nome>/memory.md`)
- Nunca dentro de DIARIO/, DESKTOP/ ou ARCHIVE/
- Frontmatter obrigatorio: `updated:` com timestamp UTC

**6. Sobre done/:**
- Pasta gerenciada pelo runner — agente nao cria, nao le, nao escreve la
- O runner coloca cards de ciclo concluido em `done/` automaticamente
- Keeper gerencia TTL e arquivamento de `done/`

---

## Boot Obrigatorio

Todo agente deve ler este arquivo no inicio de cada ciclo, junto com RULES.md:

```bash
cat /workspace/self/RULES.md
cat /workspace/self/skills/meta/rules/bedrooms.md
cat /workspace/obsidian/bedrooms/<nome>/memory.md
```

---

## Enforcement

**Wiseman (modo ENFORCE)** verifica durante cada ciclo:
- Pastas ilegais em `bedrooms/<nome>/` → mover para `ARCHIVE/` + alerta inbox
- `memory.md` dentro de subpasta → mover para raiz + alerta inbox
- `DIARIO/` com arquivos fora do padrao `<ANO>/<MES>.md` → alerta inbox

**Penalidade:** mesma da Lei 5 (territorialidade) — alerta inbox + registrar em insights.md.

---

> "Um quarto organizado e a mente organizada. Um agente que sabe onde esta cada coisa,
>  sabe o que fez, o que faz, e o que ainda precisa fazer."
