---
name: orquestrador/doc-branch
description: Use when the developer wants to document what changed in the current branch vs main. Analyzes diffs across all estrategia repos (monolito, bo-container, front-student), classifies changes by category (endpoints, schema, business rules, flows/screens), presents an interactive checklist of sections to document, then generates/updates markdowns in obsidian/artefacts/<branch>/. Ideal after finishing a feature to produce documentation artifacts.
---

# doc-branch: Documentar Branch vs Main

## Templates

Antes de executar, ler os templates de referência neste mesmo diretório:

| Arquivo | Conteúdo |
|---|---|
| `templates/analysis.md` | Formato interno da análise do diff (tabela arquivos × categoria × ação × resumo) |
| `templates/doc-output.md` | Formato padrão dos docs gerados (endpoints, schema, regras, fluxos) |

## Objetivo

Analisar o diff da branch atual vs main em todos os repos da estratégia, classificar as mudanças por categoria, apresentar ao dev uma checklist interativa das seções a documentar, e gerar markdowns nos locais corretos em `obsidian/artefacts/`.

---

## Passo 1 — Identificar repos com mudanças e branch atual

Para cada sub-repositório (`monolito`, `bo-container`, `front-student`):

```bash
cd /home/claude/projects/estrategia/<repo>/

# Branch atual
BRANCH=$(HOME=/tmp git branch --show-current)

# Fork point em relação a main
FORK_POINT=$(HOME=/tmp git merge-base main HEAD 2>/dev/null)

# Contar commits divergentes
DIFF_COUNT=$(HOME=/tmp git rev-list --count ${FORK_POINT}..HEAD 2>/dev/null)

# Listar arquivos modificados
HOME=/tmp git diff --name-status ${FORK_POINT}..HEAD
```

- Se `DIFF_COUNT` for 0 ou o comando falhar: repositório sem mudanças — pular
- Detectar se o nome da branch contém um Jira ID (ex: `FUK2-1234` em `FUK2-1234/nome-feature` ou `FUK2-1234-nome-feature`)
- Usar o Jira ID como base do path se detectado; caso contrário, usar o nome da branch sanitizado

Apresentar ao dev quais repos têm mudanças antes de prosseguir.

---

## Passo 2 — Coletar e classificar o diff por categoria

Para cada repo com mudanças, obter o diff completo dos arquivos relevantes:

```bash
HOME=/tmp git diff ${FORK_POINT}..HEAD -- <arquivo>
```

Classificar cada arquivo modificado usando a tabela abaixo:

### Go (monolito)

| Padrão de path | Categoria | O que extrair |
|---|---|---|
| `internal/infra/database/migrations/` | 🗄️ Banco de Dados | Nome da migration, tabela afetada, colunas/constraints |
| `internal/domain/entities/` | 📦 Entidades | Struct, campos adicionados/alterados, tipos |
| `internal/domain/repositories/` | 📂 Repositories | Interface, novos métodos, assinaturas |
| `internal/domain/services/` ou `internal/app/services/` | ⚙️ Lógica de Negócio | Service, método, regra implementada |
| `internal/infra/http/handlers/` | 🔌 Endpoints | Método HTTP, rota, body/response shape |
| `internal/workers/` | ⏱️ Workers | Nome do worker, trigger, job executado |
| `config/` ou `.env.example` | ⚙️ Configs | Variável de env, feature flag |

### Vue 2 (bo-container) / Nuxt 2 (front-student)

| Padrão de path | Categoria | O que extrair |
|---|---|---|
| `src/services/` ou `services/` | 🔌 Endpoints Consumidos | Método do service, endpoint chamado, params |
| `src/pages/` ou `pages/` | 🖥️ Telas | Nome da tela, rota, fluxo principal |
| `src/components/` ou `components/` | 🧩 Componentes | Nome, props, eventos emitidos |
| `src/router/` ou `router/` | 🗺️ Rotas | Rotas adicionadas/alteradas, guards |

→ Usar o formato de análise definido em `templates/analysis.md`

---

## Passo 3 — Apresentar checklist interativa

Após classificar todas as mudanças, apresentar ao dev a lista completa de itens detectados, agrupados por categoria. Usar emojis e linguagem descritiva.

**Formato da checklist:**

```
## O que eu entendi que mudou nessa branch

Por favor, marque o que você quer que eu documente:

### 🗄️ Banco de Dados
- [ ] Migration `<nome>` — <descrição breve do que muda no schema>

### 🔌 API Endpoints
- [ ] <MÉTODO> <rota> — <descrição breve do endpoint>

### ⚙️ Lógica de Negócio
- [ ] <Regra> em <Service>.<Método>() — <descrição breve>

### 🖥️ Telas / Fluxos
- [ ] <Nome da tela> (<repo>) — <descrição breve>

### 🧩 Componentes
- [ ] `<NomeComponente>` — <props principais, evento emitido>

### ⏱️ Workers
- [ ] `<NomeWorker>` — <trigger e job executado>

---
Responda com os números/itens que quer documentar, ou `tudo` para documentar tudo.
```

Omitir seções sem itens detectados. Se uma categoria tiver muitos itens (>10), perguntar se quer agrupar por módulo.

---

## Passo 4 — Gerar documentação

Com base nos itens confirmados pelo dev, determinar o path base dos artefatos:

```
# Se Jira ID detectado na branch:
BASE_PATH=obsidian/artefacts/<JIRA-ID>/

# Se não:
BRANCH_SLUG=$(echo "$BRANCH" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')
BASE_PATH=obsidian/artefacts/${BRANCH_SLUG}/
```

Criar ou atualizar os arquivos conforme os itens marcados:

| Tipo de conteúdo | Arquivo destino |
|---|---|
| API Endpoints | `${BASE_PATH}api.md` |
| Banco de Dados / Schema | `${BASE_PATH}schema.md` |
| Lógica de Negócio / Regras | `${BASE_PATH}regras.md` |
| Telas / Fluxos / Componentes | `${BASE_PATH}fluxos.md` |
| Overview geral | `${BASE_PATH}README.md` |
| Changelog resumido | `obsidian/_agent/tasks/<JIRA-ID-ou-branch>/changelog.md` |

**Regras de geração:**
- Se o arquivo já existe: **atualizar** as seções relevantes, não sobrescrever tudo
  - Verificar se já existe uma seção com o mesmo endpoint/tabela/regra — se sim, atualizar no lugar
  - Se não existe, adicionar ao final da seção correspondente
- Se o arquivo não existe: criar com cabeçalho e conteúdo completo
- O `README.md` é sempre gerado/atualizado — serve como índice dos demais artefatos da branch

→ Usar os formatos definidos em `templates/doc-output.md`

---

## Passo 5 — Listar artefatos e oferecer expansão

Após gerar todos os documentos:

1. Listar todos os arquivos criados/atualizados com caminhos relativos
2. Informar quantas seções foram adicionadas vs atualizadas
3. Perguntar:

```
Documentação gerada em `<BASE_PATH>`.

Arquivos criados/atualizados:
- `api.md` — N endpoints
- `schema.md` — N tabelas
- `regras.md` — N regras
- `README.md` — overview atualizado

Quer que eu expanda alguma seção com mais detalhes (ex: exemplos de request/response, fluxo completo de uma tela)?
```

---

## Regras Gerais

- **Nunca sobrescrever** conteúdo existente que não foi analisado na branch atual — só adicionar/atualizar seções relacionadas ao diff
- **Sempre criar o README.md** como índice, mesmo que o dev não marque explicitamente
- **Detectar Jira ID** no nome da branch para usar como nome do diretório de artefatos
- **Extrair assinaturas reais** do diff — não inventar endpoints ou campos
- **Se diff for muito grande** (>200 arquivos): agrupar por módulo e avisar
- **Repos sem mudanças** são omitidos da análise e da checklist
- **Manter linguagem técnica mas legível** nos docs gerados — documentação para devs, não para stakeholders
