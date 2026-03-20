---
name: code/analysis/diff
description: Roda difftree.py e renderiza o output no Chrome com HTML preservando as cores ANSI. Wrapper do estrategia:glance com camada de visualização no browser. Use quando quiser a árvore de arquivos modificados no Chrome em vez do terminal.
---

# code/analysis/diff — Árvore de Diff no Chrome

## Argumentos

```
/code:analysis:diff [--repos monolito|bo|front|all] [--compare origin/main]
```

Defaults: `--repos all`, `--compare origin/main`

## Processo

### Passo 1 — Rodar difftree.py

O script já existe em `/workspace/mnt/estrategia/difftree.py`.

```bash
cd /workspace/mnt/estrategia/
python3 difftree.py 2>&1 | python3 -m ansi2html > /tmp/diff_output.html
```

Se `ansi2html` não estiver disponível:
```bash
pip install ansi2html --quiet
python3 difftree.py 2>&1 | ansi2html > /tmp/diff_output.html
```

### Passo 2 — Envolver em HTML dark

Criar `/tmp/diff_chrome.html` com o output do ansi2html encapsulado num wrapper dark Catppuccin:

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body {
    background: #1e1e2e;
    color: #cdd6f4;
    font-family: 'JetBrains Mono', monospace;
    padding: 1.5rem;
    margin: 0;
  }
  pre { margin: 0; white-space: pre; }
  /* Override ansi2html background */
  .ansi2html-content { background: transparent !important; }
</style>
</head>
<body>
<!-- INJECT_ANSI2HTML_OUTPUT -->
</body>
</html>
```

### Passo 3 — Abrir no Chrome

```bash
HTML_B64=$(base64 -w 0 /tmp/diff_chrome.html)
python3 /workspace/zion/scripts/chrome-relay.py nav "data:text/html;base64,${HTML_B64}"
```

## Alternativa sem ansi2html

Se preferir, rodar o script diretamente e usar ANSI capture manual:

```python
import subprocess, base64

result = subprocess.run(
    ['python3', '/workspace/mnt/estrategia/difftree.py'],
    capture_output=True, text=True
)
# Converter ANSI para HTML CSS inline via regex simples
# e encapsular no wrapper dark acima
```

## Relação com estrategia:glance

- `estrategia:glance` → output no terminal
- `code:analysis:diff` → mesmo conteúdo, renderizado no Chrome

Para customizar keywords de highlight (feature ativa), editar diretamente `difftree.py` na linha:
```python
CHAPTER_KW = ['chapter', 'toc', 'content_tree', ...]
```
