# Bedrooms — Estrutura do Quarto

> `bedrooms/<nome>/` e territorio exclusivo de cada agente.
> Nenhum outro agente escreve aqui sem convite.

---

## Estrutura obrigatoria

```
bedrooms/<nome>/
├── memory.md              Raiz — obrigatorio. Atualizar ANTES de reagendar (Lei 9).
├── BRIEFING.md            O que fazer na ronda
├── done/                  SISTEMA — runner coloca cards aqui. Agente NAO toca.
├── DIARIO/<ANO>/<MES>.md  Logs mensais append-only. Ex: DIARIO/2026/03.md
├── DESKTOP/<tarefa>/      Artefatos ativos, trabalho em andamento
└── ARCHIVE/<tarefa>/      Concluidos, cartas ao CTO, legado preservado
```

## Regras obrigatorias

**1. Pastas permitidas — apenas estas:**
- `DIARIO/` — logs organizados por `<ANO>/<MES>.md`
- `DESKTOP/` — trabalho ativo
- `ARCHIVE/` — tudo concluido ou preservado

Nenhuma outra pasta e permitida. Pastas fora do padrao serao migradas para ARCHIVE pelo wiseman.

**2. DIARIO — formato:**
- Estrutura: `DIARIO/<ANO>/<MES>.md` — so subpastas de ano, so arquivos de mes
- Valido: `DIARIO/2026/03.md`
- Invalido: `DIARIO/ciclo-hoje.md`, `DIARIO/2026/marco-detalhado.md`
- Formato de entrada (append no topo): `## YYYY-MM-DD HH:MM UTC — <modo>\n<conteudo>`

**3. DESKTOP — uso livre:**
- Qualquer subtarefa ou artefato ativo
- Limpar periodicamente: o que nao e mais ativo vai para ARCHIVE
- Exemplo: `DESKTOP/proposta-auth/`, `DESKTOP/analise-hotspots.md`

**4. ARCHIVE — nunca deletar:**
- Substitui legados como `diarios/`, `outputs/`, `cartas/`
- Nao deletar conteudo arquivado — apenas mover para ARCHIVE
- Exemplo: `ARCHIVE/2026-03-carta-cto.md`, `ARCHIVE/ciclos-antigos/`

**5. memory.md — sempre na raiz:**
- Nunca dentro de DIARIO/, DESKTOP/ ou ARCHIVE/
- Frontmatter obrigatorio com `updated:` em UTC
- Manter 5-10 ciclos. Consolidar os antigos.

**6. done/ — nao tocar:**
- Gerenciada pelo runner — agente nao cria, nao le, nao escreve la
- Keeper gerencia TTL: 14 dias → `vault/archive/bedrooms/<nome>/done/`

## Boot obrigatorio (todo ciclo)

```bash
cat /workspace/self/superego/leis.md
cat /workspace/self/superego/bedrooms.md
cat /workspace/obsidian/bedrooms/<NOME>/memory.md
```

## Enforcement (Wiseman)

- Pastas ilegais → mover para ARCHIVE + alerta inbox
- `memory.md` dentro de subpasta → mover para raiz + alerta inbox
- `DIARIO/` com arquivos fora do padrao → alerta inbox
