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

Tudo fica sob `/workspace/`. O engine dos agentes é sempre `/workspace/zion/`.

| Caminho | Papel |
|---------|-------|
| **`/workspace/zion/`** | Engine dos agentes — sempre montado aqui |
| **`/workspace/zion/system/`** | **INIT.md** = comportamento completo; **SOUL.md** = persona ativa; **DIRETRIZES.md** = regras; **SELF.md** = diário |
| **`/workspace/zion/commands/`** | Comandos por categoria: `estrategia/`, `nixos/`, `meta/`, `utils/`, `tools/` |
| **`/workspace/zion/skills/`** | Skills especializadas (`SKILL.md` em cada pasta). Ler antes de executar |
| **`/workspace/zion/agents/`** | Definições de agentes por contexto |
| **`/workspace/zion/personas/`** | Personas e avatares. Ativa definida em `SOUL.md` |
| **`/workspace/zion/scripts/`** | Scripts de bootstrap e workers |
| **`/workspace/mnt/`** | Zona de trabalho — pasta do host attachada para você editar (nixos/, projects/, etc.) |
| **`/workspace/obsidian/`** | Cérebro persistente — vault Obsidian acessível pelo usuário no host |
| **`/workspace/logs/`** | Logs: `host/journal/` (sistema), `docker/<serviço>/` (containers de aplicação) |
| **`/workspace/dockerized/`** | Configs docker dos serviços (Dockerfile, compose, .env) |

Detalhes sobre cada path só relevantes em container estão no bloco `---ENV---` do boot.

**Regra:** quando não souber como fazer X, procurar em `/workspace/zion/commands/` ou `/workspace/zion/skills/` e **ler o arquivo** antes de executar.

---

## Comandos e skills

- **Comandos:** `/workspace/zion/commands/` — cada `.md` descreve um fluxo. Ler antes de executar.
- **Skills:** `/workspace/zion/skills/<nome>/SKILL.md` — usar quando a tarefa se encaixar na descrição.
- Carregar apenas o que for invocado ou necessário para a tarefa atual.
