---
name: code/analysis/objects
description: Lista todos os objetos modificados na branch atual por categoria e repositório (handlers, services, repos, workers, pages, components, etc.). Extrai rota HTTP de handlers Go e nome de funções exportadas. Use quando quiser ver "o que foi tocado?" de forma organizada por camada.
---

# code/analysis/objects — Objetos Modificados por Categoria

## Argumentos

```
/code:analysis:objects [--repo monolito|bo|front|all] [--format terminal|chrome]
```

Defaults: `--repo all`, `--format terminal`

## Templates

Ler `templates/layers.md` para as regras de path→layer por repositório.

## Passo 1 — Coletar arquivos modificados

Para cada repo ativo (conforme `--repo`):

```bash
cd /workspace/mnt/estrategia/<repo>/
git diff origin/main --name-status
```

Formato de saída: `M\tpath/to/file.go` ou `A\tpath/to/file.go`

Repos e paths:
- `monolito`    → `/workspace/mnt/estrategia/monolito/`
- `bo`          → `/workspace/mnt/estrategia/bo-container/`
- `front`       → `/workspace/mnt/estrategia/front-student/`

## Passo 2 — Classificar por camada

Usar as regras em `templates/layers.md` para mapear cada arquivo para sua camada.

Para cada arquivo classificado, tentar extrair metadados:

**Go (monolito):**
```bash
# Extrair rota HTTP de handlers
grep -m1 '@Router' <arquivo> | sed 's/.*@Router \(.*\) \[.*/\1/'
# Extrair método HTTP
grep -m1 '@Router' <arquivo> | grep -oP '\[(GET|POST|PUT|DELETE|PATCH)\]'
# Extrair nome da função principal exportada
grep -m1 '^func [A-Z]' <arquivo> | sed 's/func \([A-Za-z]*\).*/\1/'
```

**Vue/JS (bo-container, front-student):**
```bash
# Extrair nome do componente/page (nome do arquivo sem extensão)
basename <arquivo> .vue
# Detectar se é novo (status A) ou modificado (status M)
```

## Passo 3 — Formatar saída

### Format: terminal

```
── monolito ──────────────────────────────────────────

  Handlers
    + apps/bff/main/ldi/get_course_structure.go    GET /mci/my-courses/slug/:slug/toc
    ~ apps/bff/main/ldi/get_course.go              GET /mci/courses/slug/:slug

  Services
    + BuildAndSaveContentTree                      services/course/
    ~ getStructuredWithDocItems                    services/course/

  Repositories
    + GetCachedStructure                           repositories/course/cache.go

  Workers
    + HandleBuildCourseToc                         handlers/course/worker.go

  Migrations
    + 2026030512000000_add_content_tree_to_courses.sql

── bo-container ──────────────────────────────────────

  Pages
    ~ pages/ldi/ViewToc/index.vue

  Components
    + components/ldi/Modals/ModalTocRebuilding/index.vue  [NOVO]

── front-student ─────────────────────────────────────

  Containers
    ~ modules/ldi-poc/containers/LdiCourse.vue

  Composables
    ~ composables/Course.js
```

**Legenda de símbolos:**
- `+` arquivo novo (status A)
- `~` arquivo modificado (status M)
- `x` arquivo removido (status D)

**Cores ANSI sugeridas:**
- `+` verde `\033[38;5;83m`
- `~` amarelo `\033[38;5;214m`
- `x` vermelho `\033[38;5;196m`
- Header do repo: ciano para monolito, magenta para front-student, verde para bo-container
- Categoria (Handlers, Services...): branco bold

### Format: chrome

Gerar HTML com o mesmo conteúdo usando `<pre>` com ansi2html ou CSS inline para cores.
Abrir via:
```bash
python3 /workspace/self/scripts/chrome-relay.py nav "data:text/html;base64,<BASE64>"
```

## Regras de exibição

- Categorias vazias são omitidas
- Mostrar `[NOVO]` em destaque para arquivos com status `A`
- Mocks e arquivos `_test.go` / `.spec.js` aparecem numa categoria separada "Tests/Mocks" no final
- Migrations mostram só o nome do arquivo (sem path)
- Services/composables: mostrar nome da função exportada se extraível, senão mostrar path curto
