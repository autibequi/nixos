---
name: code/analysis/diff
description: Renderiza árvore interativa de diff no Chrome — pastas colapsáveis, clique em arquivo brilha todos os diretórios ancestrais até a raiz, breadcrumb fixo no rodapé. Tema Catppuccin Mocha dark. Use quando quiser navegar visualmente os arquivos modificados da branch.
---

# code/analysis/diff — Árvore Interativa de Diff no Chrome

## Argumentos

```
/code:analysis:diff [--repos monolito|bo|front|all] [--compare origin/main]
```

Defaults: `--repos all` (detecta todos com diff), `--compare origin/main`

## Template

Ler `templates/interactive-tree.html` — contém:
- Funções Python (`build_tree`, `squash`, `render_tree_html`) para gerar o `{{TREE_HTML}}`
- HTML completo com CSS/JS inline
- Placeholders e script de uso completo

## Funcionalidades do viewer

| Interação | Comportamento |
|---|---|
| Clique numa **pasta** | Colapsa/expande a subárvore (animação suave) |
| Clique num **arquivo** | Destaca o arquivo em azul + brilha todos os dirs ancestrais até a raiz |
| **Breadcrumb** (rodapé) | Mostra o caminho completo do arquivo selecionado |
| **◆** (roxo) | Pastas/arquivos que contêm keywords da feature ativa |

## Processo

### Passo 1 — Obter diff

```bash
cd /home/claude/projects/estrategia/<REPO>/
HOME=/tmp git branch --show-current        # branch atual
git diff origin/main --name-status         # lista de arquivos
```

Para múltiplos repos, repetir para cada um e combinar numa página com seções separadas.

### Passo 2 — Gerar tree HTML

Usar as funções `build_tree` + `squash` + `render_tree_html` do template.
Reset `_node_id[0] = 0` antes de cada repo.

### Passo 3 — Substituir placeholders e abrir

Ver script completo em `templates/interactive-tree.html`.

```bash
b64=$(base64 -w0 /tmp/diff.html)
python3 /workspace/zion/scripts/chrome-relay.py nav "data:text/html;base64,${b64}"
```

## Keywords de feature (◆)

Ajustar `CHAPTER_KW` no script para a feature em andamento:

```python
CHAPTER_KW = ['chapter', 'toc', 'content_tree', 'course_chapter', 'getCourse']
# Outros exemplos:
# ['payment', 'checkout', 'order']
# ['enrollment', 'subscription']
```

## Repos e paths

| Repo | Path |
|---|---|
| monolito | `/home/claude/projects/estrategia/monolito` |
| bo-container | `/home/claude/projects/estrategia/bo-container` |
| front-student | `/home/claude/projects/estrategia/front-student` |
