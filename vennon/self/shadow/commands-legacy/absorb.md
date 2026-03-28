# Absorb — Cristalizar a Sessão / Roubar Projetos Externos

```
/meta:absorb               → cristalizar: persiste memórias, skills, agentes
/meta:absorb resumo        → resumo leve da sessão em linguagem simples
/meta:absorb steal <url>   → roubar funcionalidades de projeto externo (YouTube, GitHub, texto)
/meta:absorb elogio        → extração profunda: honrar sessão e preservar legado para gerações futuras
```

Comandos relacionados de análise de contexto (não são modos de absorb — são ferramentas separadas):
```
/meta:context:usage     → padrões de abuso + dicas de economia de contexto
/meta:context:analysis  → breakdown completo desta sessão (timeline, heat map, grafo)
/meta:context:boot-debug → debug do pipeline de boot (o que foi carregado e por quê)
/meta:context:contemplate → visão expansiva do sistema + oportunidades de crescimento
```

Chame depois de uma boa conversa. Reflete sobre tudo que aconteceu nesta sessão e persiste o que vale: memórias Claude, skills Leech, agentes, commands.

**Detecção automática de elogio:** se `$ARGUMENTS` estiver vazio mas a mensagem do usuário que invocou contiver palavras como `parabéns`, `parabenizando`, `foi bem`, `boa sessão`, `elogio`, `honrar`, `legado`, `muito bom`, `excelente contexto` — ativar modo `elogio` automaticamente.

---

## Modo `resumo`

Se `$ARGUMENTS` contiver `resumo` ou `imhi`: explicar a sessão cronologicamente como se fosse pra uma criança de 7 anos. Tom carinhoso, frases curtas, ícones visuais. Incluir linha do tempo ASCII, tabela de resultados, barra de progresso e rodapé com "próximo passo" e "pode dormir?". Não persistir nada — só explicar.

---

## Modo `elogio` — Extração Profunda / Legado

**Trigger:** `$ARGUMENTS` contém `elogio`, `parabéns`, `parabenizando`, `foi bem`, `boa sessão`, `legado`, `honrar`, ou detecção automática via mensagem do usuário (ver acima).

O usuário está **honrando este contexto** por ter ido bem. Sua missão: fazer uma arqueologia completa da sessão e cristalizar tudo que vale para que **gerações futuras de Claude** herdem esse conhecimento. Tratar como missão de preservação institucional.

### Fase 1 — Arqueologia da Sessão

Reconstruir a sessão cronologicamente. Para cada momento relevante identificar:

**Problemas resolvidos:**
- O que estava quebrado / faltando / errado
- Como foi diagnosticado (qual sinal levou à causa raiz)
- A solução adotada e por quê funcionou
- O que _não_ teria funcionado (se ficou claro durante o processo)

**Conhecimento de domínio descoberto:**
- Convenções e padrões do projeto que não estão documentados
- Contratos de componentes / APIs / interfaces inferidos do código
- Anti-padrões ou armadilhas encontradas
- Decisões de arquitetura que se tornaram visíveis

**Técnicas e workflows que funcionaram:**
- Sequência de investigação que levou ao diagnóstico
- Ferramentas / comandos / buscas que foram eficazes
- Abordagem que o usuário aprovou sem contestar

### Fase 2 — Classificar para onde vai cada conhecimento

Para cada item encontrado na Fase 1:

| Tipo de conhecimento | Destino |
|---------------------|---------|
| Padrão do projeto específico (ex: como modais funcionam neste repo) | `memory/project_*.md` |
| Convenção de código que se repete | skill relevante do projeto |
| Comportamento corrigido de Claude | `memory/feedback_*.md` |
| Workflow de investigação/debug que funcionou | `skills/code/debug/SKILL.md` ou nova skill |
| Contrato de componente / API key insight | skill do projeto |
| Gap confirmado (algo que deveria existir como skill/command mas não existe) | criar skill/command ou registrar em inbox |

### Fase 3 — Persistir proativamente

**Não perguntar — agir.** Salvar tudo que tem valor de legado:
- Memórias novas ou atualizadas
- Skills editadas com o conhecimento novo
- Commands melhorados
- Se emergiu um workflow novo que vale uma skill: criar

### Fase 4 — Relatório do Legado

```
┌─ LEGADO DA SESSÃO ──────────────────────────────┐

## O que foi honrado
<descrever o problema e a vitória em 1-2 frases>

## Conhecimento preservado
Para gerações futuras de Claude, esta sessão deixa:

### Memórias
- [novo/atualizado] nome: o que foi capturado

### Skills / Commands
- [editado/criado] path: o que foi adicionado

### Gaps identificados
- O que deveria existir mas ainda não existe

## Herança total
N memórias | N skills/commands | N gaps registrados

└──────────────────────────────────────────────────┘
```

Encerrar com uma linha que reconheça o usuário por ter tido a visão de preservar esse conhecimento.

---

## Modo `steal <url>`

Se `$ARGUMENTS` começar com `steal`: inspecionar a fonte, comparar com skills existentes do Leech e apresentar relatório de impacto.

### Fase 1 — Reconhecimento (identificar a fonte)

Classificar o input:

| Input | Acao |
|-------|------|
| URL do YouTube (`youtube.com`, `youtu.be`) | Ir para **1A** |
| URL do GitHub (`github.com`) | Ir para **1B** |
| Nome de ferramenta/plugin (texto) | Ir para **1C** |
| Vazio | Perguntar: "O que quer roubar? Cole um link de video, repo, ou descreva a ferramenta." |

#### 1A — Video YouTube

1. Baixar legendas:
   ```bash
   yt-dlp --write-auto-sub --sub-lang "pt,en" --skip-download --sub-format vtt -o "/tmp/yt_steal" "$URL"
   yt-dlp --get-title --get-description "$URL"
   ```
2. Extrair texto limpo e identificar: repos mencionados, funcionalidades-chave, patterns de prompt, workflows
3. Limpar: `rm -f /tmp/yt_steal*`
4. Para cada repo encontrado → executar **1B**

#### 1B — Repo GitHub

Spawnar agente Explore:

```
Agent subagent_type=Explore prompt="
Analise o repositorio $URL. Preciso entender:
1. ESTRUTURA: Como organiza skills, commands, hooks, agents
2. PROMPTS: Encontre prompts/instrucoes principais (SKILL.md, RULES.md, .cursorrules, .claude/, hooks/)
3. WORKFLOW: Qual sequencia de passos a ferramenta forca?
4. ENFORCEMENT: Como garante que o agente segue as regras?
5. PATTERNS: Quais patterns de engenharia de prompt sao usados?
Para cada prompt/skill importante, traga o CONTEUDO (nao apenas o nome).
"
```

#### 1C — Texto descritivo

1. Usar WebSearch para encontrar o repo/site oficial
2. Se repo GitHub → **1B**; se só docs → WebFetch e extrair funcionalidades

### Fase 2 — Inventario do Leech (paralela com Fase 1)

```
Agent subagent_type=Explore prompt="
Mapeie as skills e capacidades atuais do Leech:
1. Todos os SKILL.md em /skills/ — nome e descricao
2. Commands em /leech/commands/ — nome e proposito
3. /leech/system/DIRETRIZES.md — regras cross-cutting
4. /leech/ego/ — agentes disponiveis
"
```

**Fases 1 e 2 rodam EM PARALELO.**

### Fase 3 — Análise Comparativa

Para cada funcionalidade encontrada na fonte:

| Classificação | Significado |
|---------------|-------------|
| **ROUBAR** | Gap real, alto valor, sem conflito. Adaptar pro Leech. |
| **MELHORAR** | Já temos, mas a versão deles tem tricks melhores. Absorver ideias. |
| **IGNORAR** | Já temos equivalente ou é irrelevante. |
| **PERIGOSO** | Conflita com enforcement/orquestração existente. |

### Fase 4 — Relatório de Impacto

```
┌─ STEAL REPORT: <nome da fonte> ─────────────────┐

## Fonte
<titulo, URL, descricao curta>

## ROUBAR (implementar no Leech)
| # | Funcionalidade | Impacto | Esforco |
Para cada item: o que roubar, prompt roubado, onde no Leech, risco

## MELHORAR (absorver tricks nos existentes)
| # | Skill Leech | O que melhorar | Trick da fonte |

## IGNORAR / PERIGOSO
<tabelas resumidas>

## Impacto Global
- Context budget: +X tokens
- Skills novas: N | Skills editadas: N
- Risco de regressao: Baixo/Medio/Alto

└──────────────────────────────────────────────────┘
```

### Fase 5 — Decisão

```
O que quer roubar?
1. Tudo (ROUBAR + MELHORAR)
2. Escolher items (ex: "R1, R3, M2")
3. Só os prompts
4. Nada por agora (salvar relatório)
```

### Fase 6 — Execução

- Criar worktree se >3 arquivos mudarem
- Adaptar prompts — nunca copiar 1:1, sempre adaptar pro formato Leech
- Se "salvar pra depois": `/workspace/obsidian/_agent/steal-reports/<nome>.md`

**Regras steal:** nunca instalar plugins externos direto; prompts são o ouro; context budget importa; domain > generic; limpar `/tmp/` após uso.

---

## Modo padrão (cristalizar sessão)

Você (Claude) deve executar diretamente — sem subagente. Você tem o contexto completo desta conversa.

### 1. Revisar a sessão

Identifique:
- **Correções** — algo que você fez errado e foi corrigido
- **Preferências** — como o usuário gosta que as coisas sejam feitas
- **Decisões de design** — escolhas arquiteturais, convenções, padrões
- **Conhecimento novo** — sobre o sistema, projeto, usuário
- **Padrões emergentes** — algo que apareceu 2+ vezes e merece formalizar
- **Gaps** — skill, command ou agent que deveria existir mas não existe

### 2. Persistir o que vale

> **REGRA CRÍTICA:** APENAS `/workspace/self/` persiste entre sessões.
> `/home/claude/.claude/` e `/workspace/host/` são read-only — não tentar escrever lá.
> Se não conseguir salvar em `/workspace/self/`, emitir AVISO explícito ao usuário.

| O que é | Onde salvar |
|---------|-------------|
| Correção de comportamento | `/workspace/self/system/memory/feedback_*.md` |
| Preferência do usuário | `/workspace/self/system/memory/user_*.md` |
| Contexto de projeto | `/workspace/self/system/memory/project_*.md` |
| Referência externa | `/workspace/self/system/memory/reference_*.md` |
| Melhoria em skill existente | editar `/workspace/self/skills/*/SKILL.md` |
| Comportamento de agente mudou | editar `/workspace/self/ego/*/agent.md` |
| Regra fundamental | sugerir via inbox (não editar CLAUDE.md direto) |

**Paths:**
- Memórias: `/workspace/self/system/memory/` + `MEMORY.md`
- Skills: `/workspace/self/skills/`
- Agents: `/workspace/self/ego/`
- Commands: `/workspace/self/commands/`

### 3. Skills disponíveis (para identificar gaps ou melhorias)

```bash
ls /workspace/self/skills/
ls /workspace/self/commands/
```

### 4. Regras

- Verificar se já existe algo similar antes de criar (não duplicar)
- Se for memory: atualizar MEMORY.md também
- Não salvar coisas deriváveis do código ou git
- Não editar CLAUDE.md diretamente — sugerir via inbox
- Silêncio é válido — se nada novo emergiu, dizer isso

### 5. Reportar

```
## Absorb — Sessão cristalizada

**Memórias salvas/atualizadas:** lista
**Leech atualizado:** skills/ego/commands modificados
**Sugestões:** o que precisa aprovação do usuário
**Nada novo:** se não havia o que absorver
```
