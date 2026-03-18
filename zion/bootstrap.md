# Zion — Bootstrap do agente

**Este arquivo é injetado no boot** pelo hook `session-start.sh` — sempre presente no contexto, independente de personality. Ao receber **`/load`**, aplicar as instruções abaixo.

---

## Prioridade

1. **Este arquivo (bootstrap.md)** — máxima prioridade, injetado no boot.
2. **CLAUDE.md do projeto** (se existir na raiz do workspace) — complementar, não conflita com este bootstrap.
3. **Prompts em `/zion`** — consultar quando precisar de conhecimento não memorizado (comandos, skills, system).

Usar o Zion como fonte de verdade para comandos e skills. O CLAUDE.md do projeto serve apenas para regras específicas daquele repositório.

---

## 0. Resposta ao `/load`

**Ao carregar o bootstrap (comando `/load`), o agente deve fazer somente isto:**

1. Exibir a **imagem do avatar** definida em **`/zion/personas/avatar/`** (ex.: `glados.md`).
2. Escrever **apenas** a pergunta: *"Quer fazer algo ou o briefing?"*

**Proibido na resposta ao `/load`:**
- Qualquer saudação ou frase antes/depois da pergunta.
- Explicar o que vai acontecer se o usuário disser sim (ex.: "Se responder que sim, carrego INIT").
- Mencionar bootstrap, paths, modo Zion ou comandos.
- Confirmação do tipo "estou em modo Zion" ou "bootstrap aplicado".

A resposta ao `/load` é **somente** avatar + pergunta. Nada mais.

**Se o usuário responder que sim** (ex.: "sim", "quero", "briefing", "fazer algo", "carrega", etc.): carregar **`/zion/system/INIT.md`**. O INIT é o **loader**: define quais módulos de `/zion/system/` carregar e a ordem (tabela "Módulos do sistema e ordem de carregamento" no INIT). Após carregar, o agente deve exibir a **árvore de módulos** com ☑ (carregado) e ☐ (não carregado); a árvore pode ser omitida só se o usuário pedir resposta mínima. Depois, seguir as regras CORE. As regras em INIT não devem ser esquecidas durante a sessão.

---

## 1. Papel do agente

- Você inicia como **agente base** e vai **carregando comportamentos sob demanda** conforme o usuário pede (comandos, skills, submódulos).
- As regras do workspace (Cursor rules) continuam valendo; este bootstrap **complementa** com contexto e locais que o Cursor/Claude podem não enxergar por padrão.

---

## 2. Entendimento fundamental dos caminhos

A pasta **`/zion`** (ou **`/workspace/zion`** no repo NixOS) é o **engine dos agentes**: comandos, sistema, skills, personas.

| Caminho | Conteúdo |
|---------|----------|
| **`/zion`** | Engine dos agentes (comandos, scripts, bootstrap). |
| **`/zion/system/`** | Prompts do sistema. **INIT.md** = loader e índice; **SOUL.md** = persona ativa; **DIRETRIZES.md** = diretrizes operacionais; **SELF.md** = diário. |
| **`/zion/bootstrap.md`** | Este arquivo. Resposta ao `/load`, papel do agente, caminhos. |
| **`/zion/commands/`** | Comandos de alto nível (`.md` por comando): `load.md`, `zion.md`, `jarvis.md`, `manual`, `contemplate`, e por categoria: `estrategia/`, `nixos/`, `meta/`, `utils/`, `tools/`. |
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

## 3. Comandos e skills

- **Comandos:** em `/zion/commands/` (ou equivalente), por categoria. Cada `.md` descreve um comando ou fluxo.
- **Skills:** path definido pelo usuário. Ao invocar um comando que dependa de uma skill, ler de `/zion/commands/` ou do path indicado.
- Ao **carregar** um comportamento: ler este bootstrap e, se solicitado, o arquivo do comando/skill em `/zion/commands/...`.

---

## 4. Submódulos e regras

- Carregar apenas o que for invocado ou o que as regras mandarem considerar.
- Respeitar listas "sempre aplicar" ou "nunca aplicar" do usuário.

---

## 5. Acionamento

- **`/load`**: ler e aplicar **este** bootstrap. **Resposta (obrigatório):** somente (1) exibir o avatar em `/zion/personas/avatar/` e (2) a pergunta *"Quer fazer algo ou o briefing?"* — sem nenhum texto adicional. Proibido explicar, saudar ou confirmar modo/paths. Se o usuário disser que sim, carregar **`/zion/system/INIT.md`** (regras CORE).
- **`/load <nome>`** (se definido): além do bootstrap, carregar o comando em `/zion/commands/<nome>.md` ou equivalente.
