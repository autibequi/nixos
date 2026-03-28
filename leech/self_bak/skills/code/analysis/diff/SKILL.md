---
name: code/analysis/diff
description: Renderiza árvore interativa de diff no Chrome — pastas colapsáveis, ancestor glow, path bar sticky, anotações dim por linha, ícone copy, tema Catppuccin Mocha dark. Use quando quiser navegar visualmente os arquivos modificados da branch.
---

# code/analysis/diff — Árvore Interativa de Diff no Chrome

## Argumentos

```
/code:analysis:diff [--repos monolito|bo|front|all] [--compare origin/main]
```

Defaults: `--repos all` (detecta todos com diff), `--compare origin/main`

## Sub-skills

| Arquivo | O que faz | Quando usar |
|---|---|---|
| `codediff.md` | **Code diff side-by-side** — diff2html-cli, tema dark, JetBrains Mono | Ver linhas +/- reais, code walk, review |
| `templates/generator.py` | Árvore interativa flat com anotações | Navegar quais arquivos mudaram |
| `templates/generator_by_layer.py` | Árvore segregada por camada | Quais handlers/services/repos foram tocados |

---

## Funcionalidades do viewer

| Interação | Comportamento |
|---|---|
| Clique numa **pasta** | Colapsa/expande a subárvore (animação suave) |
| Clique num **arquivo** | Destaca em azul + brilha todos os dirs ancestrais (ancestor glow) |
| **Path bar** (sticky abaixo do header) | Path completo + tag curta + detalhe longo do arquivo selecionado |
| **Anotação dim** (coluna fixa `left: 460px`) | `// tag` ciano escuro ao lado de cada arquivo com descrição |
| **Ícone copy** (SVG, aparece no hover) | Copia o path relativo para o clipboard; flash verde ao copiar |
| **`// desc ON/OFF`** (botão no header) | Toggle para mostrar/esconder todas as anotações inline |
| **◆** (roxo) | Pastas/arquivos que contêm keywords da feature ativa (`CHAPTER_KW`) |

---

## Processo completo

### Passo 1 — Obter diff

```bash
cd /home/claude/projects/estrategia/<REPO>/
HOME=/tmp git branch --show-current
git diff origin/main --name-status > /tmp/<repo>_diff.txt
```

### Passo 2 — Copiar e configurar o gerador

Para diff flat (árvore única):
```bash
cp /home/claude/.claude/skills/code/analysis/diff/templates/generator.py /tmp/gen_diff.py
```

Para diff por camada (Handlers, Services, Repos...):
```bash
cp /home/claude/.claude/skills/code/analysis/diff/templates/generator_by_layer.py /tmp/gen_diff.py
```

Editar as variáveis no topo:

```python
REPO        = 'monolito'
BRANCH      = 'FUK2-11746-vibed/cached-ldi-toc'
DIFF_FILE   = '/tmp/mono_diff.txt'
OUTPUT_FILE = '/tmp/mono_diff.html'

CHAPTER_KW = ['chapter', 'toc', 'content_tree']  # keywords da feature ativa
```

### Passo 3 — Preencher DESCRIPTIONS (opcional mas recomendado)

O dict `DESCRIPTIONS` mapeia path relativo → `('tag curta', 'detalhe longo')`.

- **tag**: aparece inline na linha (dim cyan) e em destaque no path bar ao selecionar
- **detalhe**: só aparece no path bar ao selecionar o arquivo

```python
DESCRIPTIONS = {
    'apps/bff/internal/handlers/main/ldi/get_course_structure.go':
        ('novo endpoint GET /toc',
         'retorna estrutura flat (chapters+items+has_blocks) sem dados pesados'),

    'services/course/content_tree.go':
        ('BuildAndSaveContentTree',
         'serializa CourseStructureResponse no JSONB do curso para cache persistente'),
}
```

Focar nas ~20 arquivos mais importantes. Arquivos não mapeados ficam sem anotação inline.

### Passo 4 — Gerar o HTML

```bash
python3 /tmp/gen_diff.py > /dev/null
# HTML puro salvo em OUTPUT_FILE
```

### Passo 5 — Abrir no Chrome via relay

Salvar o HTML em `/tmp/chrome-relay/diff.html` e navegar via relay:

```bash
cp /tmp/<repo>_diff_annotated.html /tmp/chrome-relay/diff.html
python3 /workspace/self/scripts/chrome-relay.py nav "http://leech:8766/diff.html"
```

O servidor do relay já serve `/tmp/chrome-relay/` em `http://leech:8766/` — UTF-8 correto, sem limites de tamanho, sem servidor extra.

---

## Variante: por camada (`generator_by_layer.py`)

Agrupa os arquivos em seções colapsáveis por tipo (Handlers, Services, Repositories,
Workers, etc.) — cada seção com sua própria mini-árvore interativa.

Usar quando quiser responder: *"quais handlers/services/repos foram tocados nessa branch?"*

### Configurar LAYERS

```python
# Monolito
LAYERS = [
    ('Handlers',      '#89b4fa', lambda p: '/handlers/' in p or p.startswith('handlers/')),
    ('Services',      '#a6e3a1', lambda p: '/services/'  in p or p.startswith('services/')),
    ('Repositories',  '#94e2d5', lambda p: '/repositories/' in p or p.startswith('repositories/')),
    ('Workers',       '#fab387', lambda p: '/workers/'   in p or p.startswith('workers/')),
    ('Migrations',    '#f9e2af', lambda p: 'migration'   in p.lower()),
    ('Mocks',         '#6c7086', lambda p: '/mocks/'     in p or p.startswith('mocks/')),
    ('Outros',        '#45475a', lambda p: True),   # catch-all — deve ser o ultimo
]

# BO Container
LAYERS = [
    ('Pages',       '#89b4fa', lambda p: '/pages/'      in p),
    ('Components',  '#a6e3a1', lambda p: '/components/' in p),
    ('Services',    '#94e2d5', lambda p: '/services/'   in p),
    ('Routes',      '#fab387', lambda p: '/router/'     in p),
    ('Outros',      '#45475a', lambda p: True),
]

# Front Student
LAYERS = [
    ('Pages',       '#89b4fa', lambda p: '/pages/'       in p),
    ('Containers',  '#a6e3a1', lambda p: '/containers/'  in p),
    ('Components',  '#94e2d5', lambda p: '/components/'  in p),
    ('Composables', '#fab387', lambda p: '/composables/' in p),
    ('Services',    '#cba6f7', lambda p: '/services/'    in p),
    ('Types',       '#f9e2af', lambda p: '/types/'       in p),
    ('Outros',      '#45475a', lambda p: True),
]
```

A ordem importa: cada arquivo entra na **primeira** camada que der match.

### Rodar

```bash
cp /home/claude/.claude/skills/code/analysis/diff/templates/generator_by_layer.py /tmp/gen_diff.py
# editar REPO, BRANCH, DIFF_FILE, OUTPUT_FILE, LAYERS, DESCRIPTIONS
python3 /tmp/gen_diff.py > /dev/null
# abrir com o servidor HTTP (Passo 5 acima, ajustando HTML_F)
```

---

## Keywords de feature (◆)

```python
CHAPTER_KW = ['chapter', 'toc', 'content_tree', 'course_chapter', 'getCourse']
# Outros exemplos:
# ['payment', 'checkout', 'order', 'billing']
# ['enrollment', 'subscription', 'plan']
# ['notification', 'email', 'webhook']
```

---

## Repos e paths

| Repo | Path |
|---|---|
| monolito | `/home/claude/projects/estrategia/monolito` |
| bo-container | `/home/claude/projects/estrategia/bo-container` |
| front-student | `/home/claude/projects/estrategia/front-student` |

---

## Detalhes técnicos

### Funções principais (ambos os templates)

| Funcao | O que faz |
|---|---|
| `build_tree(files)` | Constrói árvore dict aninhada a partir de lista `(status, path)` |
| `squash(tree)` | Colapsa dirs com filho único (sem arquivos) em `pai/filho` |
| `count_types(tree)` | Conta A/M/D recursivamente para badges de pasta |
| `has_chapter_tree(tree)` | Verifica se algum descendente tem keyword da feature |
| `render_tree_html(tree, prefix)` | Gera HTML da árvore com todos os data-attributes |

### Por que servidor HTTP e não inject/Blob?

- `data:text/html` como argumento CLI: `OSError: Argument list too long` para HTMLs grandes
- `document.write(atob(...))`: encoding Latin-1, quebra caracteres UTF-8 (▾, ├─, ◆)
- `Blob URL via location.href`: Chrome bloqueia navegacao de `about:blank` para blob
- **Servidor HTTP local porta 9876**: confiavel, UTF-8 correto, sem limites de tamanho

### Por que `left: 460px` e nao `margin-left: auto`?

`margin-left: auto` funciona em flex mas os itens têm larguras variáveis
(profundidade + comprimento do nome). Com `position: absolute; left: 460px`
todas as anotações ficam na mesma coluna visual independente do nível de aninhamento.
