---
name: code/analysis/diff/codediff
description: Viewer de code diff lado a lado no Chrome — diff2html-cli via nix-shell, tema dark oficial, JetBrains Mono injetado. Mostra linhas +/- reais com syntax highlight, file list colapsável. Usar quando o usuário quer ver o que mudou no código, não só quais arquivos.
---

# code/analysis/diff/codediff — Code Diff Viewer (side-by-side)

Diferente da árvore interativa (que mostra *quais* arquivos mudaram), este viewer
mostra *o que* mudou — linhas adicionadas/removidas lado a lado com syntax highlight.

## Quando usar

- Usuário quer ver o código que entrou, não só a lista de arquivos
- Review de PR / code walk
- Comparar antes/depois de um bloco específico

## Processo

### Passo 1 — Obter o diff completo

```bash
git -C /home/claude/projects/estrategia/<REPO> diff origin/main > /tmp/<repo>_full_diff.txt
```

### Passo 2 — Garantir servidor HTTP

```bash
# Checar se já está rodando
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8766/ | grep -q 200 || \
  (cd /tmp/chrome-relay && python3 -m http.server 8766 &>/dev/null &)
```

### Passo 3 — Gerar HTML com diff2html-cli

```bash
nix-shell -p nodePackages.diff2html-cli --run \
  "diff2html -i file -s side -t html --cs dark -o stdout -- /tmp/<repo>_full_diff.txt" \
  2>/dev/null > /tmp/chrome-relay/codediff.html
```

Flags:
- `-s side` — side-by-side (esquerda=antes, direita=depois)
- `-t html` — output HTML completo standalone
- `--cs dark` — tema dark oficial (sem CSS custom)

### Passo 4 — Injetar fonte

```bash
python3 /workspace/self/scripts/chrome-relay.py nav "http://127.0.0.1:8766/codediff.html"
```

Depois injetar JetBrains Mono via CDP:

```bash
python3 /workspace/self/scripts/chrome-relay.py inject "
const link = document.createElement('link');
link.rel = 'stylesheet';
link.href = 'https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&display=swap';
document.head.appendChild(link);
const style = document.createElement('style');
style.textContent = '* { font-family: \"JetBrains Mono\", monospace !important; }';
document.head.appendChild(style);
'OK';
"
```

## Script completo (copiar e ajustar REPO/BRANCH)

```python
import os, subprocess

REPO   = 'monolito'  # monolito | bo-container | front-student
REPO_PATH = f'/home/claude/projects/estrategia/{REPO}'
DIFF_TXT  = f'/tmp/{REPO}_full_diff.txt'
OUT_HTML  = '/tmp/chrome-relay/codediff.html'
RELAY     = '/workspace/self/scripts/chrome-relay.py'

# 1. diff
os.system(f'git -C {REPO_PATH} diff origin/main > {DIFF_TXT}')

# 2. servidor
os.makedirs('/tmp/chrome-relay', exist_ok=True)
os.system('curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8766/ | grep -q 200 || '
          '(cd /tmp/chrome-relay && python3 -m http.server 8766 &>/dev/null &)')

# 3. gerar HTML
os.system(
    f'nix-shell -p nodePackages.diff2html-cli --run '
    f'"diff2html -i file -s side -t html --cs dark -o stdout -- {DIFF_TXT}" '
    f'2>/dev/null > {OUT_HTML}'
)

# 4. abrir
os.system(f'python3 {RELAY} nav "http://127.0.0.1:8766/codediff.html"')

# 5. fonte
os.system(f"""python3 {RELAY} inject "
const l=document.createElement('link');
l.rel='stylesheet';
l.href='https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&display=swap';
document.head.appendChild(l);
const s=document.createElement('style');
s.textContent='*{{font-family:\\"JetBrains Mono\\",monospace!important}}';
document.head.appendChild(s);'OK';" """)

print("OK — aberto no Chrome")
```

## Script one-liner (bash, copiar direto)

```bash
REPO=monolito
git -C /home/claude/projects/estrategia/$REPO diff origin/main > /tmp/${REPO}_diff.txt && \
mkdir -p /tmp/chrome-relay && \
nix-shell -p nodePackages.diff2html-cli --run \
  "diff2html -i file -s side -t html --cs dark -o stdout -- /tmp/${REPO}_diff.txt" \
  2>/dev/null > /tmp/chrome-relay/codediff.html && \
python3 /workspace/self/scripts/chrome-relay.py nav "http://127.0.0.1:8766/codediff.html" && \
sleep 1 && \
python3 /workspace/self/scripts/chrome-relay.py inject \
  "const l=document.createElement('link');l.rel='stylesheet';l.href='https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&display=swap';document.head.appendChild(l);const s=document.createElement('style');s.textContent='*{font-family:\"JetBrains Mono\",monospace!important}';document.head.appendChild(s);" 2>&1
```

> Trocar `REPO=monolito` por `bo-container` ou `front-student` conforme necessário.

## Armadilhas (lições aprendidas)

| Problema | Causa | Fix |
|----------|-------|-----|
| Fonte não aparece | `inject` antes da página carregar | `sleep 1` entre o `nav` e o `inject` |
| Servidor 404 | `/tmp/chrome-relay/` não servido pelo relay nativo | Subir `python3 -m http.server 8766` em `/tmp/chrome-relay/` |
| Tema dark feio | CSS custom sobrepondo o tema oficial | Usar só `--cs dark` no CLI, sem override manual |
| `colorScheme: 'dark'` via JS não funcionou bem | CSS specificity — o diff2html-cli gera HTML mais limpo que a API JS | Preferir sempre o CLI ao invés de diff2html via CDN JS |
| Diff embutido em JS quebra | Backticks no diff quebram template literal JS | Se precisar embutir: usar `base64.b64encode` + `atob()` no browser |
| `nix-shell` lento na primeira vez | Download dos pacotes (~30s) | Fica em cache — segunda execução é instantânea |

## Notas

- `nix-shell` baixa diff2html-cli na primeira vez (~30s), fica em cache depois
- Arquivo HTML gerado é standalone — pode ser aberto sem servidor se necessário
- Para ver só um arquivo: usar `git diff origin/main -- <path>` no Passo 1
- O servidor HTTP na 8766 precisa estar rodando: `cd /tmp/chrome-relay && python3 -m http.server 8766 &`
