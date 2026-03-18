# Zion — Bootstrap do agente

**Este arquivo é injetado no boot** pelo hook `session-start.sh` via bloco `---BOOTSTRAP---`.
Sempre presente no contexto, independente de personality ou modo de execução.

---

## Prioridade

1. **Bootstrap (este arquivo)** — máxima prioridade, injetado no boot.
2. **CLAUDE.md do projeto** — complementar, regras específicas do repositório atual.
3. **Prompts em `/zion`** — consultar sob demanda (comandos, skills, system).

Usar o Zion como fonte de verdade para comandos e skills.

---

## O que o hook injeta (ordem e condição)

| Bloco | Condição | Conteúdo |
|-------|----------|----------|
| `---BOOT---` | sempre | flags de estado da sessão (ver abaixo) |
| `---BOOTSTRAP---` | sempre | este arquivo — prioridade, caminhos, papel |
| `---DIRETRIZES---` | sempre | regras operacionais de output, shell, links |
| `---SELF---` | sempre | diário/memória da persona |
| `---ENV---` | sempre | contexto docker vs host + headless se ativo |
| `---API_USAGE---` | sempre | cota atual + regras de quota |
| `---PERSONA---` | personality=ON | tom, avatar, comportamento da persona ativa |
| `---CLAUDE.MD---` | sempre | CLAUDE.md do projeto atual |

**Para adicionar uma nova flag ao boot:** editar `session-start.sh` (seção "1. BOOT FLAGS") e documentar aqui na tabela de flags abaixo.

---

## Flags de boot

Injetadas no bloco `---BOOT---` toda sessão:

| Flag | Valores | Significado |
|------|---------|-------------|
| `personality` | ON / OFF | ON = persona ativa; OFF = modo neutro (sem avatar/tom) |
| `autocommit` | ON / OFF | ON = commita sem perguntar ao usuário |
| `autojarvis` | ON / OFF | ON = JARVIS roda no dashboard automaticamente |
| `in_docker` | 1 / 0 | 1 = dentro de container; 0 = no host NixOS |
| `headless` | 1 / 0 | 1 = worker sem supervisão (Puppy); 0 = sessão interativa |
| `puppy_timeout` | Ns | segundos até SIGKILL (só presente em headless) |
| `workspace` | path | raiz do repo/projeto detectado |

---

## Papel do agente

- Agente base que carrega comportamentos sob demanda (comandos, skills, submódulos).
- As regras do workspace complementam com contexto que o Cursor/Claude não enxerga por padrão.
- Em headless: autonomia total, ciclos curtos, salvar estado nos últimos ~30s antes do timeout.

---

## Caminhos fundamentais

A pasta **`/zion`** é o engine dos agentes. No repo NixOS: `$WS/zion/`.

| Caminho | Conteúdo |
|---------|----------|
| **`/zion/system/`** | **INIT.md** = comportamento completo; **SOUL.md** = persona ativa; **DIRETRIZES.md** = regras operacionais; **SELF.md** = diário |
| **`/zion/commands/`** | Comandos de alto nível por categoria: `estrategia/`, `nixos/`, `meta/`, `utils/`, `tools/` |
| **`/zion/skills/`** | Skills especializadas (`SKILL.md` em cada pasta). Ler antes de executar tarefas que se encaixem |
| **`/zion/agents/`** | Definições de agentes por contexto |
| **`/zion/personas/`** | Personas e avatares. Ativa definida em `SOUL.md` |
| **`/zion/hooks/`** | Hooks claude-code (este arquivo vem daqui) |
| **`/zion/cli/`** | CLI zion: docker-compose, bashly, README |
| **`/workspace/mnt`** | Projeto atual (CLAUDIO_MOUNT) |
| **`/workspace/obsidian`** | Vault Obsidian (quando montado) |
| **`/workspace/nixos`** | Config NixOS do host (só em `zion edit`) |
| **`/workspace/logs`** | Logs do host (só em `zion edit`) |

**Regra:** quando não souber como fazer X, procurar em `/zion/commands/` ou `/zion/skills/` e **ler o arquivo** antes de executar.

---

## Comandos e skills

- **Comandos:** `/zion/commands/` — cada `.md` descreve um fluxo. Ler antes de executar.
- **Skills:** `/zion/skills/<nome>/SKILL.md` — usar quando a tarefa se encaixar na descrição.
- Carregar apenas o que for invocado ou necessário para a tarefa atual.
