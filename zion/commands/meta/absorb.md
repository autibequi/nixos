# Absorb — Cristalizar a Sessão / Roubar Projetos Externos

```
/meta:absorb               → cristalizar: persiste memórias, skills, agentes
/meta:absorb resumo        → resumo leve da sessão em linguagem simples
/meta:absorb steal <url>   → roubar funcionalidades de projeto externo (YouTube, GitHub, texto)
```

Chame depois de uma boa conversa. Reflete sobre tudo que aconteceu nesta sessão e persiste o que vale: memórias Claude, skills Zion, agentes, commands.

---

## Modo `resumo`

Se `$ARGUMENTS` contiver `resumo` ou `imhi`: explicar a sessão cronologicamente como se fosse pra uma criança de 7 anos. Tom carinhoso, frases curtas, ícones visuais. Incluir linha do tempo ASCII, tabela de resultados, barra de progresso e rodapé com "próximo passo" e "pode dormir?". Não persistir nada — só explicar.

---

## Modo `steal <url>`

Se `$ARGUMENTS` começar com `steal`: inspecionar a fonte, comparar com skills existentes do Zion e apresentar relatório de impacto.

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

### Fase 2 — Inventario do Zion (paralela com Fase 1)

```
Agent subagent_type=Explore prompt="
Mapeie as skills e capacidades atuais do Zion:
1. Todos os SKILL.md em /zion/skills/ — nome e descricao
2. Commands em /zion/commands/ — nome e proposito
3. /zion/system/DIRETRIZES.md — regras cross-cutting
4. /zion/agents/ — agentes disponiveis
"
```

**Fases 1 e 2 rodam EM PARALELO.**

### Fase 3 — Análise Comparativa

Para cada funcionalidade encontrada na fonte:

| Classificação | Significado |
|---------------|-------------|
| **ROUBAR** | Gap real, alto valor, sem conflito. Adaptar pro Zion. |
| **MELHORAR** | Já temos, mas a versão deles tem tricks melhores. Absorver ideias. |
| **IGNORAR** | Já temos equivalente ou é irrelevante. |
| **PERIGOSO** | Conflita com enforcement/orquestração existente. |

### Fase 4 — Relatório de Impacto

```
╭─ STEAL REPORT: <nome da fonte> ─────────────────╮

## Fonte
<titulo, URL, descricao curta>

## ROUBAR (implementar no Zion)
| # | Funcionalidade | Impacto | Esforco |
Para cada item: o que roubar, prompt roubado, onde no Zion, risco

## MELHORAR (absorver tricks nos existentes)
| # | Skill Zion | O que melhorar | Trick da fonte |

## IGNORAR / PERIGOSO
<tabelas resumidas>

## Impacto Global
- Context budget: +X tokens
- Skills novas: N | Skills editadas: N
- Risco de regressao: Baixo/Medio/Alto

╰──────────────────────────────────────────────────╯
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
- Adaptar prompts — nunca copiar 1:1, sempre adaptar pro formato Zion
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

| O que é | Onde salvar |
|---------|-------------|
| Correção de comportamento | `~/.claude/projects/-workspace-mnt/memory/feedback_*.md` |
| Preferência do usuário | `memory/user_*.md` |
| Contexto de projeto | `memory/project_*.md` |
| Referência externa | `memory/reference_*.md` |
| Melhoria em skill existente | editar `zion/skills/*/SKILL.md` |
| Comportamento de agente mudou | editar `zion/agents/*/agent.md` |
| Regra fundamental | sugerir via inbox (não editar CLAUDE.md direto) |

**Paths:**
- Memórias: `~/.claude/projects/-workspace-mnt/memory/` + `MEMORY.md`
- Zion skills: `/workspace/mnt/zion/skills/`
- Zion agents: `/workspace/mnt/zion/agents/`
- Commands: `/workspace/mnt/zion/commands/`

### 3. Skills disponíveis (para identificar gaps ou melhorias)

```bash
ls /workspace/mnt/zion/skills/
ls /workspace/mnt/zion/commands/
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
**Zion atualizado:** skills/agents/commands modificados
**Sugestões:** o que precisa aprovação do usuário
**Nada novo:** se não havia o que absorver
```
