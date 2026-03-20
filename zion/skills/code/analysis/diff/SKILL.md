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

## Template

O gerador completo está em `templates/generator.py`. Script Python auto-contido:
lê o diff, constrói a árvore e gera HTML com todas as funcionalidades.

---

## Funcionalidades do viewer

| Interação | Comportamento |
|---|---|
| Clique numa **pasta** | Colapsa/expande a subárvore (animação suave) |
| Clique num **arquivo** | Destaca em azul + brilha todos os dirs ancestrais (ancestor glow) |
| **Path bar** (sticky abaixo do header) | Path completo + tag curta + detalhe longo do arquivo selecionado |
| **Anotação dim** (coluna fixa `left: 460px`) | `// tag` ciano escuro ao lado de cada arquivo com descrição |
| **Ícone copy** (SVG, aparece no hover) | Copia o path relativo para o clipboard; flash verde ao copiar |
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

```bash
cp /home/claude/.claude/skills/code/analysis/diff/templates/generator.py /tmp/gen_diff.py
```

Editar as variáveis no topo de `/tmp/gen_diff.py`:

```python
REPO        = 'monolito'
BRANCH      = 'FUK2-11746-vibed/cached-ldi-toc'
DIFF_FILE   = '/tmp/mono_diff.txt'
OUTPUT_FILE = '/tmp/mono_diff_annotated.html'

CHAPTER_KW = ['chapter', 'toc', 'content_tree']  # keywords da feature ativa
```

### Passo 3 — Preencher DESCRIPTIONS (opcional mas recomendado)

O dict `DESCRIPTIONS` mapeia path relativo → `('tag curta', 'detalhe longo')`.

- **tag**: aparece inline na linha (dim cyan) e em destaque no path bar ao selecionar
- **detalhe**: só aparece no path bar ao selecionar o arquivo

Para preencher, ler os arquivos relevantes:

```bash
git diff origin/main -- apps/bff/internal/handlers/main/ldi/get_course_structure.go | head -40
```

Exemplo:

```python
DESCRIPTIONS = {
    'apps/bff/internal/handlers/main/ldi/get_course_structure.go':
        ('novo endpoint GET /toc',
         'retorna estrutura flat (chapters+items+has_blocks) sem dados pesados de progresso/favoritos'),

    'services/course/content_tree.go':
        ('BuildAndSaveContentTree',
         'serializa CourseStructureResponse no JSONB do curso para cache persistente'),

    'repositories/course/cache.go':
        ('GetCachedStructure',
         'lê o JSONB salvo e deserializa — retorna nil se ainda não existe'),
}
```

Focar nas ~20 arquivos mais importantes. Arquivos não mapeados ficam sem anotação inline.

### Passo 4 — Gerar o HTML

```bash
python3 /tmp/gen_diff.py > /dev/null
# HTML puro salvo em OUTPUT_FILE
```

> **Importante:** redirecionar stdout para `/dev/null`. O script printa o data URL
> (legado) que não é necessário. O HTML vai para o arquivo configurado.

### Passo 5 — Abrir no Chrome via relay

**Não usar** `data:text/html` como arg de linha de comando — HTMLs grandes causam
`OSError: Argument list too long`. Usar o padrão inject:

```python
# /tmp/open_diff.py
import sys, base64, time

RELAY  = '/workspace/zion/scripts/chrome-relay.py'
HTML_F = '/tmp/mono_diff_annotated.html'

sys.argv = ['chrome-relay.py', 'nav', 'about:blank']
exec(open(RELAY).read())

time.sleep(0.4)

with open(HTML_F, 'rb') as f:
    html = f.read().decode()

b64 = base64.b64encode(html.encode()).decode()
js  = f"document.open();document.write(atob('{b64}'));document.close();"
sys.argv = ['chrome-relay.py', 'inject', js]
exec(open(RELAY).read())
```

```bash
python3 /tmp/open_diff.py
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

### Funções principais (`templates/generator.py`)

| Função | O que faz |
|---|---|
| `build_tree(files)` | Constrói árvore dict aninhada a partir de lista `(status, path)` |
| `squash(tree)` | Colapsa dirs com filho único (sem arquivos) em `pai/filho` |
| `count_types(tree)` | Conta A/M/D recursivamente para badges de pasta |
| `has_chapter_tree(tree)` | Verifica se algum descendente tem keyword da feature |
| `render_tree_html(tree, prefix)` | Gera HTML da árvore com todos os data-attributes |

### Por que `left: 460px` e não `margin-left: auto`?

`margin-left: auto` funciona em flex mas os itens têm larguras variáveis
(profundidade + comprimento do nome). Com `position: absolute; left: 460px`
todas as anotações ficam na mesma coluna visual independente do nível de aninhamento.
