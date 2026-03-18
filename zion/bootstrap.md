# Zion — Bootstrap do agente

**Este arquivo é injetado no boot** pelo hook `session-start.sh` via bloco `---BOOTSTRAP---`.
Sempre presente, independente de personality ou modo.

---

## Prioridade

1. **Bootstrap (este arquivo)** — máxima prioridade, injetado no boot.
2. **CLAUDE.md do projeto** — complementar, regras específicas do repositório atual.
3. **`/workspace/zion/`** — fonte de verdade para comandos e skills; consultar sob demanda.

---

## O que o hook injeta

| Bloco | Condição | Conteúdo |
|-------|----------|----------|
| `---BOOT---` | sempre | datetime + flags de estado |
| `---BOOTSTRAP---` | sempre | este arquivo |
| `---DIRETRIZES---` | interativo (headless=0) | regras operacionais |
| `---SELF---` | personality=ON | diário da persona |
| `---ENV---` | sempre | contexto docker/host + estrutura /workspace |
| `---API_USAGE---` | sempre | cota atual + regras por threshold |
| `---PERSONA---` | personality=ON | tom, avatar, comportamento |
| `---CLAUDE.MD---` | sempre | CLAUDE.md do projeto |

**Para adicionar flag:** editar `session-start.sh` seção `# 1. BOOT FLAGS` e adicionar linha na tabela abaixo.

---

## Flags de boot

| Flag | Valores | Significado |
|------|---------|-------------|
| `datetime` | timestamp | data e hora atual — usar para regras de cota noturna |
| `personality` | ON/OFF | ON = persona ativa |
| `autocommit` | ON/OFF | ON = commita sem perguntar |
| `autojarvis` | ON/OFF | ON = JARVIS no dashboard |
| `in_docker` | 1/0 | 1 = container; 0 = host |
| `zion_edit` | 1/0 | 1 = mnt é o repo nixos + logs montados; 0 = projeto externo |
| `headless` | 1/0 | 1 = worker Puppy sem supervisão |
| `puppy_timeout` | Ns | segundos até SIGKILL (só em headless) |
| `workspace` | path | raiz do repo/projeto detectado |

---

## Engine — `/workspace/zion/`

Tudo sob `/workspace/`. O engine dos agentes é **sempre** `/workspace/zion/`.

| Path | Conteúdo |
|------|----------|
| `system/INIT.md` | comportamento completo do agente |
| `system/SOUL.md` | persona ativa |
| `system/DIRETRIZES.md` | regras operacionais |
| `system/SELF.md` | diário |
| `commands/` | comandos por categoria: `estrategia/`, `nixos/`, `meta/`, `utils/`, `tools/` |
| `skills/` | skills especializadas — cada uma tem `SKILL.md`. Ler antes de executar |
| `agents/` | definições de agentes por contexto |
| `personas/` | personas e avatares |
| `scripts/` | bootstrap e workers |

Detalhes do `/workspace/mnt`, `/workspace/obsidian`, `/workspace/logs` estão no bloco `---ENV---`.

**Regra:** não souber como fazer X → buscar em `commands/` ou `skills/` e **ler o arquivo** antes de executar.
