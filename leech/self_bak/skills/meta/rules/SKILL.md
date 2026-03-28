---
name: meta:rules
description: "Regras do sistema Leech — entrypoint universal, leis, espacos, agentes, scheduling."
---

# meta:rules — Regras do Sistema

Entrypoint universal: `self/RULES.md` (todos carregam — curto, so referencias).
Detalhes ficam aqui e sao carregados sob demanda.

## Arquivos

| Arquivo | Conteudo |
|---------|----------|
| `self/RULES.md` | **ENTRYPOINT** — 10 leis resumidas + mapa de arquivos |
| `laws.md` | 10 leis completas + violacoes + penalidades |
| `agentroom.md` | Protocolo de ciclo — inicio, fim, memory, reagendar |
| `scheduling.md` | Scheduling de agentes + tasks one-off |
| `map.md` | Mapa de diretorios do vault |
| `spaces.md` | Regras por espaco: workshop, bedrooms, inbox, vault, trash |
| `agents.md` | Perfil rapido dos agentes (modelo, clock, funcao) |
| `bedrooms.md` | Regras do quarto — pastas permitidas (DIARIO/DESKTOP/ARCHIVE), boot obrigatorio |
| `worktrees.md` | Regra universal de implementacao via worktree — fluxo, naming, apresentacao ao CTO |

## Uso via CLI

- `/meta:rules` — exibe o entrypoint (`self/RULES.md`)
- `/meta:rules laws` — leis completas
- `/meta:rules <tema>` — abre arquivo especifico (ex: `spaces`, `scheduling`, `agents`)
- `/meta:rules edit <arquivo>` — propor edicao, aguarda confirmacao

## Manutencao

- Fonte da verdade: arquivos nesta pasta
- Entrypoint sempre curto: so referencias, nunca conteudo completo
- Ao mudar uma lei: atualizar `laws.md` primeiro, wiseman notifica via inbox
