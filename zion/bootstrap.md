# Zion — Bootstrap do agente

**Este arquivo é injetado no boot** pelo hook `session-start.sh` — sempre presente no contexto, independente de personality.

---

## Prioridade

1. **Este arquivo (bootstrap.md)** — máxima prioridade, injetado no boot.
2. **CLAUDE.md do projeto** (se existir na raiz do workspace) — complementar, não conflita com este bootstrap.
3. **Prompts em `/zion`** — consultar quando precisar de conhecimento não memorizado (comandos, skills, system).

Usar o Zion como fonte de verdade para comandos e skills. O CLAUDE.md do projeto serve apenas para regras específicas daquele repositório.

---

## Papel do agente

- Você inicia como **agente base** e vai **carregando comportamentos sob demanda** conforme o usuário pede (comandos, skills, submódulos).
- As regras do workspace (Cursor rules) continuam valendo; este bootstrap **complementa** com contexto e locais que o Cursor/Claude podem não enxergar por padrão.

---

## Caminhos fundamentais

A pasta **`/zion`** (ou **`/workspace/zion`** no repo NixOS) é o **engine dos agentes**: comandos, sistema, skills, personas.

| Caminho | Conteúdo |
|---------|----------|
| **`/zion`** | Engine dos agentes (comandos, scripts, bootstrap). |
| **`/zion/system/`** | Prompts do sistema. **INIT.md** = comportamento completo do agente; **SOUL.md** = persona ativa; **DIRETRIZES.md** = diretrizes operacionais; **SELF.md** = diário. |
| **`/zion/bootstrap.md`** | Este arquivo. Prioridade, papel do agente, caminhos. |
| **`/zion/commands/`** | Comandos de alto nível (`.md` por comando): `zion.md`, `jarvis.md`, `manual`, `contemplate`, e por categoria: `estrategia/`, `nixos/`, `meta/`, `utils/`, `tools/`. |
| **`/zion/skills/`** | Skills especializadas (cada uma em pasta com `SKILL.md`): nixos, hyprland-config, monolito/\*, orquestrador/\*, front-student/\*, bo-container/\*. **Usar a skill** quando a tarefa se encaixar. |
| **`/zion/agents/`** | Definições de agentes por contexto (monolito, nixos, orquestrador, etc.). |
| **`/zion/personas/`** | Personas (`.persona.md`) e avatares. A ativa é definida em `zion/system/SOUL.md`. |
| **`/zion/hooks/`** | Hooks claude-code (session-start, pre-tool-use, etc.). |
| **`/zion/cli/`** | CLI: docker-compose.zion, Makefile, README. |
| **`/workspace/nixos`** | Configuração NixOS do host (quando montado). |
| **`/workspace/obsidian`** | Obsidian compartilhado (quando montado). |
| **`/workspace/logs`** | Logs do host (quando montado). |
| **`/workspace/mnt`** | Pasta que o user passou (CLAUDIO_MOUNT); projeto de trabalho. |

**Regra:** nixos, obsidian, logs e mount ficam sempre **sob `/workspace`**. Quando não souber como fazer X (ex.: "adicionar handler no monolito", "editar config Hyprland"), procurar em **`/zion/commands/`** ou **`/zion/skills/`** e **ler o arquivo** antes de executar.

---

## Comandos e skills

- **Comandos:** em `/zion/commands/`, por categoria. Cada `.md` descreve um comando ou fluxo.
- **Skills:** cada uma em `/zion/skills/<nome>/SKILL.md`. Ler o SKILL.md antes de executar tarefas que se encaixem na skill.
- Carregar apenas o que for invocado ou o que as regras mandarem considerar.
