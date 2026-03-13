---
name: orquestrador/changelog
description: Use when the developer wants to see a visual summary of all changes on the current branch compared to main. Diffs each sub-repository (monolito, bo-container, front-student), categorizes changes by type (methods, services, handlers, repositories, workers, pages, components, routes), and presents a structured changelog with method names and parameters for easy validation.
---

# changelog: Gerar Changelog Visual da Branch Atual

## Templates

Antes de executar, ler os templates de referência neste mesmo diretório:

| Arquivo | Conteúdo |
|---|---|
| `templates/categorization.md` | Tabelas de categorização por repositório (path patterns, o que extrair) |
| `templates/changelog-output.md` | Formato completo de saída do changelog (tabelas, seções, resumo) |

## Objetivo

Analisar o diff de cada sub-repositório (monolito, bo-container, front-student) entre a branch atual e main, extraindo e categorizando todas as mudanças de forma visual e fácil de validar.

## Passo 1 — Identificar repositórios com mudanças

Para cada sub-repositório (`monolito/`, `bo-container/`, `front-student/`), verificar se a branch atual difere de main:

```bash
cd <repo>/
BRANCH=$(HOME=/tmp git branch --show-current)
# Se estiver em main ou sem commits divergentes, pular
FORK_POINT=$(HOME=/tmp git merge-base main HEAD 2>/dev/null)
DIFF_COUNT=$(HOME=/tmp git rev-list --count ${FORK_POINT}..HEAD 2>/dev/null)
```

Se `DIFF_COUNT` for 0 ou o comando falhar, o repositório não tem mudanças — pular.

Listar os repositórios com mudanças ao dev antes de prosseguir.

## Passo 2 — Para cada repositório com mudanças, coletar o diff

### 2a — Listar arquivos modificados/criados/deletados

```bash
cd <repo>/
HOME=/tmp git diff --name-status ${FORK_POINT}..HEAD
```

Guardar a lista completa. Classificar cada arquivo por status: `A` (adicionado), `M` (modificado), `D` (deletado).

### 2b — Obter o diff completo dos arquivos relevantes

```bash
cd <repo>/
HOME=/tmp git diff ${FORK_POINT}..HEAD -- <arquivo>
```

Ler o diff de cada arquivo relevante para extrair métodos, funções, componentes, etc.

## Passo 3 — Categorizar e extrair detalhes

Classificar cada arquivo modificado/criado nas categorias definidas por repositório.

→ Usar as tabelas de categorização definidas em `templates/categorization.md`

### Dicas de extração — Go (monolito)

**Para extrair métodos Go do diff:**
- Procurar linhas adicionadas com pattern `func (receiver) NomeMétodo(params) retorno`
- Procurar linhas adicionadas com pattern `func NomeMétodo(params) retorno`
- Para interfaces, procurar `NomeMétodo(params) retorno` dentro de blocos `type XxxInterface interface {`
- Para structs, procurar campos adicionados dentro de `type XxxStruct struct {`

**Para extrair endpoints:**
- Procurar registros de rota no diff: `.GET(`, `.POST(`, `.PUT(`, `.DELETE(`, `.PATCH(`
- Ou procurar nos arquivos de handler o path registrado

### Dicas de extração — Vue/JS (bo-container, front-student)

**Para extrair do diff Vue/JS:**
- Services: procurar `async nomeMetodo(params)` ou `nomeMetodo(params)` em classes/objetos exportados
- Props: procurar bloco `props:` e listar as props com tipos
- Eventos: procurar `$emit('nome-evento'`
- Métodos: procurar dentro de `methods: {` as funções definidas
- Computed: procurar dentro de `computed: {`

## Passo 4 — Montar o changelog visual

Apresentar o resultado usando emojis para status e tipo, e formatação markdown para facilitar a leitura. Omitir categorias vazias e repositórios sem mudanças.

→ Usar o formato definido em `templates/changelog-output.md`

## Passo 5 — Salvar changelog em arquivo

Após montar o changelog, **sempre** salvar o conteúdo completo em arquivo dentro de `vault/_agent/tasks/`, com o nome `changelog.<data>.md`, onde `<data>` é a data atual no formato `YYYY-MM-DD`.

**Onde salvar:**
- **Se invocado dentro de uma feature** (existe pasta `vault/_agent/tasks/FUK2-*/` ativa): salvar dentro da pasta da feature → `vault/_agent/tasks/<pasta>/changelog.<data>.md`
- **Se invocado standalone** (sem feature ativa): identificar a task a partir da branch atual de cada repositório e criar a pasta correspondente em `vault/_agent/tasks/`:
  1. Ler o nome da branch: `HOME=/tmp git -C <repo>/ branch --show-current`
  2. Extrair o código da task (ex: `FUK2-1234` de `FUK2-1234-descricao` ou da branch diretamente)
  3. Criar pasta `vault/_agent/tasks/<codigo>/` se não existir
  4. Salvar em `vault/_agent/tasks/<codigo>/changelog.<data>.md`
  5. Se não for possível extrair um código de task da branch (ex: branch `main`), perguntar ao dev qual código usar

Exemplo dentro de feature: `vault/_agent/tasks/FUK2-1234/changelog.2026-03-09.md`
Exemplo standalone: `vault/_agent/tasks/FUK2-1234/changelog.2026-03-09.md`

O arquivo deve conter exatamente o mesmo conteúdo markdown apresentado ao dev.

Se já existir um arquivo `changelog.<data>.md` no destino, sobrescrever com o conteúdo atualizado.

## Passo 6 — Perguntar se quer detalhes

Após apresentar o changelog e salvar o arquivo, informar o caminho do arquivo salvo e perguntar:

```
Changelog salvo em `<caminho>/changelog.<data>.md`.
Quer que eu expanda os detalhes de alguma categoria ou arquivo específico?
```

## Regras

- **Sempre salvar o changelog em arquivo dentro de `vault/_agent/tasks/`** — na pasta da feature se houver, senão criar pasta a partir do código da branch
- **Analisar o diff real** (`git diff`), não adivinhar pelas extensões
- **Extrair assinaturas completas** de métodos Go (incluindo receiver, params e retorno)
- **Extrair props e eventos** de componentes Vue (não apenas o nome do arquivo)
- **Mostrar endpoints chamados** nos services de frontend (não apenas o nome do método)
- **Categorias vazias** devem ser omitidas (não mostrar seção vazia)
- **Repositórios sem mudanças** devem ser omitidos
- **Arquivos de mock** são listados sem detalhamento (ocupam muito espaço sem valor)
- **Se o diff for muito grande** (>100 arquivos num repositório), agrupar itens similares e avisar que o changelog está resumido
- **Usar a tabela de status**: ✅ Novo, ✏️ Modificado, ❌ Deletado
