# Steal — Roubar funcionalidades de projetos externos

Inspeciona uma fonte (video YouTube, repo GitHub, URL), extrai ideias e prompts relevantes, compara com as skills existentes do Zion, e apresenta um relatorio de impacto pro user decidir o que roubar.

## Entrada
- `$ARGUMENTS`: URL de video YouTube, repo GitHub, ou texto descrevendo a ferramenta/plugin a inspecionar

## Instrucoes

### Fase 1 — Reconhecimento (identificar a fonte)

Classificar o input:

| Input | Acao |
|-------|------|
| URL do YouTube (`youtube.com`, `youtu.be`) | Ir para **1A** |
| URL do GitHub (`github.com`) | Ir para **1B** |
| Nome de ferramenta/plugin (texto) | Ir para **1C** |
| Vazio | Perguntar: "O que quer roubar? Cole um link de video, repo, ou descreva a ferramenta." |

#### 1A — Video YouTube

1. Baixar legendas com `yt-dlp`:
   ```bash
   yt-dlp --write-auto-sub --sub-lang "pt,en" --skip-download --sub-format vtt -o "/tmp/yt_steal" "$URL"
   ```
2. Pegar titulo e descricao:
   ```bash
   yt-dlp --get-title --get-description "$URL"
   ```
3. Extrair texto limpo das legendas:
   ```bash
   sed 's/<[^>]*>//g' /tmp/yt_steal.*.vtt | grep -v '^$' | grep -v '^WEBVTT' | grep -v '^Kind:' | grep -v '^Language:' | grep -v '^\s*$' | grep -v '^[0-9][0-9]:[0-9][0-9]' | sort -u
   ```
4. Da transcricao e descricao, extrair:
   - **Repositorios mencionados** (URLs do GitHub)
   - **Funcionalidades-chave** descritas
   - **Conceitos/patterns** de engenharia de prompt
   - **Workflows** (sequencia de passos que a ferramenta forca)
5. Limpar: `rm -f /tmp/yt_steal*`
6. Para cada repo encontrado → executar **1B**
7. Se nenhum repo encontrado, montar analise apenas com a transcricao → ir para **Fase 2**

#### 1B — Repo GitHub

Spawnar agente Explore para inspecionar o repositorio:

```
Agent subagent_type=Explore prompt="
Analise o repositorio $URL. Preciso entender:

1. ESTRUTURA: Como o projeto organiza seus arquivos (skills, commands, hooks, agents, configs)
2. PROMPTS: Encontre os prompts/instrucoes principais que o projeto injeta no LLM. Busque por:
   - Arquivos SKILL.md, RULES.md, .cursorrules, .claude/, hooks/
   - System prompts, meta-instrucoes, enforcement rules
   - Fetch o conteudo raw dos arquivos mais importantes
3. WORKFLOW: Qual sequencia de passos a ferramenta forca? (ex: plan→approve→execute)
4. ENFORCEMENT: Como garante que o agente segue as regras? (hooks? injection? pressure tests?)
5. PATTERNS: Quais patterns de engenharia de prompt sao usados? (TDD, socratic, review gates, etc.)
6. INTEGRACAO: Como se instala/ativa? (marketplace, npm, manual, hooks)

Para cada prompt/skill importante que encontrar, traga o CONTEUDO (nao apenas o nome).
Foque em ideias que possam ser adaptadas, nao na ferramenta como um todo.
"
```

#### 1C — Texto descritivo

1. Usar WebSearch para encontrar o repo/site oficial
2. Se encontrar repo GitHub → executar **1B**
3. Se encontrar apenas site/docs → usar WebFetch nos docs principais e extrair funcionalidades

### Fase 2 — Inventario do Zion (o que ja temos)

Spawnar agente Explore para mapear skills existentes:

```
Agent subagent_type=Explore prompt="
Mapeie as skills e capacidades atuais do Zion:

1. Ler todos os SKILL.md em /zion/skills/ — extrair nome e descricao de cada um
2. Ler os commands em /zion/commands/ — extrair nome e proposito
3. Ler /zion/system/DIRETRIZES.md — extrair regras cross-cutting
4. Ler /zion/hooks/claude-code/ — entender o que e injetado no boot
5. Ler /zion/agents/ — listar agentes especializados disponiveis

Retorne uma lista estruturada:
- Skills: nome, descricao, dominio (tools/mono/bo/front/orq/nixos)
- Commands: nome, proposito
- Hooks: o que cada hook faz
- Diretrizes: regras ativas
- Agents: nome, especializacao
"
```

**IMPORTANTE:** Fase 1 e Fase 2 devem rodar EM PARALELO (mesmo message, multiplos Agent calls).

### Fase 3 — Analise Comparativa

Com os resultados das Fases 1 e 2, construir a tabela de comparacao:

Para cada funcionalidade/conceito encontrado na fonte externa:

1. **Existe no Zion?** — Buscar equivalente nas skills/commands/hooks/diretrizes
2. **Se existe:** qual o nivel de cobertura? (completo, parcial, superficial)
3. **Se nao existe:** e um gap real ou algo irrelevante pro nosso contexto?
4. **Conflito?** — implementar isso quebraria algo existente?
5. **Valor dos prompts:** os prompts/instrucoes da fonte sao melhores que os nossos? Tem enforcement tricks que podemos roubar?

Classificar cada item:

| Classificacao | Significado |
|---------------|-------------|
| **ROUBAR** | Gap real, alto valor, sem conflito. Adaptar pro Zion. |
| **MELHORAR** | Ja temos, mas a versao deles tem tricks/prompts melhores. Absorver ideias. |
| **IGNORAR** | Ja temos equivalente ou melhor. Ou irrelevante pro nosso contexto. |
| **PERIGOSO** | Conflita com enforcement/orquestracao existente. Nao implementar. |

### Fase 4 — Relatorio de Impacto

Apresentar o relatorio no formato abaixo. **Este e o output principal — caprichar.**

```
╭─ STEAL REPORT: <nome da fonte> ─────────────────╮

## Fonte
<titulo, URL, descricao curta>

## Resumo
<2-3 frases: o que a ferramenta faz e qual a filosofia>

## Funcionalidades Encontradas

### ROUBAR (implementar no Zion)

| # | Funcionalidade | O que faz | Impacto no Zion | Esforco |
|---|---------------|-----------|-----------------|---------|
| 1 | ... | ... | ... | Baixo/Medio/Alto |

Para cada item ROUBAR, detalhar:
- **O que roubar:** descricao concreta do que implementar
- **Prompt roubado:** trecho do prompt/instrucao original que vamos adaptar
- **Onde no Zion:** arquivo(s) a criar/editar
- **Risco:** o que pode dar errado
- **Expectativa:** o que muda no comportamento do agente apos implementar

### MELHORAR (absorver tricks nos existentes)

| # | Skill Zion | O que melhorar | Trick da fonte |
|---|-----------|----------------|----------------|
| 1 | ... | ... | ... |

### IGNORAR (ja temos ou irrelevante)

| # | Funcionalidade | Por que ignorar |
|---|---------------|-----------------|
| 1 | ... | Ja coberto por <skill> / Irrelevante porque ... |

### PERIGOSO (nao implementar)

| # | Funcionalidade | Por que e perigoso |
|---|---------------|--------------------|
| 1 | ... | Conflita com <skill/hook/diretriz> porque ... |

## Impacto Global

- **Context budget:** +X tokens estimados no boot (se hooks mudarem)
- **Skills novas:** N skills a criar
- **Skills editadas:** N skills a modificar
- **Hooks:** mudancas necessarias em hooks? (sim/nao)
- **Risco de regressao:** Baixo/Medio/Alto

╰──────────────────────────────────────────────────╯
```

### Fase 5 — Decisao do User

Perguntar usando AskUserQuestion:

```
O que quer roubar?

Opcoes:
1. Roubar TUDO (implementar todos os items ROUBAR + MELHORAR)
2. Escolher items (informe os numeros, ex: "R1, R3, M2")
3. So roubar os prompts (copiar tricks sem criar skills novas)
4. Nada por agora (salvar relatorio pra depois)
```

### Fase 6 — Execucao (se user aceitar)

Para cada item aceito:

1. **Criar worktree** se forem muitas mudancas (>3 arquivos)
2. **Implementar** seguindo o plano do relatorio
3. **Adaptar prompts** — nunca copiar 1:1, sempre adaptar pro formato e convenções Zion
4. **Testar** — rodar hook ou skill pra confirmar que funciona
5. **Mostrar evidencia** (ref: DIRETRIZES verificacao)

Se user escolheu "salvar pra depois":
- Salvar relatorio em `/workspace/obsidian/_agent/steal-reports/<nome-fonte>.md`
- Informar path pro user

## Regras

1. **Nunca instalar plugins externos direto** — sempre adaptar pro formato Zion
2. **Prompts sao o ouro** — o valor nao e a ferramenta em si, e como ela instrui o LLM
3. **Context budget importa** — cada token injetado no boot tem custo. Preferir DIRETRIZES (cross-cutting) sobre skills separadas quando possivel
4. **Domain > Generic** — skills do Zion com conhecimento especifico (Go, Vue, Jira) sao mais valiosas que genericas. Ao roubar, sempre adicionar seccoes de dominio
5. **Enforcement sem conflito** — nunca criar meta-skills que competem com INIT.md/DIRETRIZES.md
6. **Respeitar o padrao** — skills novas seguem o formato existente (SKILL.md com frontmatter YAML ou header markdown). Commands em `zion/commands/`. Hooks em `zion/hooks/`
7. **Fontes simultaneas** — se o user passar multiplas URLs, processar em paralelo (multiplos Agent calls)
8. **Limpar temporarios** — sempre remover arquivos em /tmp/ apos uso
