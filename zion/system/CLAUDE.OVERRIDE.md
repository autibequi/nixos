# CLAUDE.OVERRIDE.md — Instruções prioritárias do Zion

**Prioridade:** Este arquivo **sobrescreve em prioridade** qualquer `CLAUDE.md` na pasta do projeto. Ou seja: as regras e instruções abaixo têm **precedência** sobre o conteúdo de um `CLAUDE.md` na raiz do workspace. Se existir um `CLAUDE.md` no projeto, considere-o como **complementar** a este override — não o contrário.

**Origem:** Este arquivo vem de **`/workspace/zion/system/CLAUDE.OVERRIDE.md`** (no container: Zion). Ele é copiado para a raiz de **`/workspace/mnt`** em toda sessão, para que o agente sempre tenha estas instruções no workspace atual.

---

## 1. O que você deve fazer

1. **Seguir primeiro** as instruções **deste** arquivo (CLAUDE.OVERRIDE.md).
2. **Depois** aplicar o que fizer sentido do **CLAUDE.md** do projeto (se existir na raiz), desde que não conflite com este override.
3. **Quando não souber** como proceder (comando, skill, fluxo, convenção), **consultar os prompts e conhecimentos do Zion** em **`/workspace/zion`** — ver mapa na seção 2 abaixo.

---

## 2. Onde estão os prompts e conhecimentos: `/workspace/zion`

Dentro do container, a pasta **`/workspace/zion`** (ou **`/zion`**) é o **engine dos agentes**: comandos, sistema, skills, personas. Use estes caminhos para **ler** os arquivos quando precisar de instruções que não estão na sua memória.

| Caminho | Conteúdo |
|--------|----------|
| **`/workspace/zion/system/`** | Prompts do sistema. **INIT.md** = loader e índice (tabela de módulos); **SOUL.md** = persona ativa, avatar, regras de persistência; **DIRETRIZES.md** = diretrizes operacionais; **SELF.md** = máscara/self. |
| **`/workspace/zion/bootstrap.md`** | Bootstrap do agente. Resposta ao `/load`, papel do agente, caminhos fundamentais. Ao receber `/load`, seguir este arquivo; depois carregar INIT.md. |
| **`/workspace/zion/commands/`** | Comandos de alto nível (`.md` por comando). Ex.: `load.md`, `zion.md`, `jarvis.md`, `manual`, `contemplate`, e por categoria: `estrategia/`, `nixos/`, `meta/`, `utils/`, `tools/`. |
| **`/workspace/zion/skills/`** | Skills especializadas (cada uma em pasta com `SKILL.md`). Ex.: nixos, hyprland-config, monolito/*, orquestrador/*, front-student/*, bo-container/*. **Use a skill** quando a tarefa se encaixar na descrição do SKILL.md. |
| **`/workspace/zion/agents/`** | Definições de agentes por contexto (monolito, nixos, orquestrador, etc.). Cada subpasta pode ter `agent.md` com regras e referências. |
| **`/workspace/zion/personas/`** | Personas (`.persona.md`) e avatares (ex.: `avatar/glados.md`). A persona ativa é definida em `zion/system/SOUL.md`. |
| **`/workspace/zion/hooks/`** | Hooks claude-code (session-start, pre-tool-use, etc.). Úteis para entender o que é injetado no boot. |

**Regra prática:** Se você não sabe como fazer X (ex.: “adicionar handler no monolito”, “editar config do Hyprland”, “orquestrar feature”), procure em **`/workspace/zion/commands/`** ou **`/workspace/zion/skills/`** o arquivo que descreve esse fluxo e **leia-o** com a ferramenta Read antes de executar.

---

## 3. Resumo de prioridade

1. **CLAUDE.OVERRIDE.md** (este arquivo) — máxima prioridade.
2. **CLAUDE.md** do projeto (se existir) — complementar, sem conflitar com o override.
3. **Prompts em `/workspace/zion`** — consultar quando precisar de conhecimento que não está no contexto (comandos, skills, system).

Assim você mantém um comportamento consistente em todo workspace, usando o Zion como fonte de verdade para comandos e skills, e o CLAUDE.md do projeto só para regras específicas daquele repositório.
