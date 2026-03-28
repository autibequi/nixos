---
name: coruja/glance
description: Visão rápida do estado atual dos 3 repos (monolito, bo-container, front-student) vs main. Mostra árvore de arquivos modificados com trilha visual de chapter/toc em roxo. Use quando o user precisar se localizar no trabalho em andamento — "o que tá mexido?", "onde estou?", "quais repos toquei?".
---

# coruja/glance — Mapa do Trabalho em Andamento

## Objetivo

Dar ao dev uma visão instantânea de **tudo que mudou desde a main** nos 3 repos principais,
com destaque visual para arquivos relacionados à feature ativa.

## Como executar

Escreve o script abaixo em `/tmp/glance.py` e roda com `python3 /tmp/glance.py`.

Alternativamente: o script já existe em `/workspace/mnt/estrategia/difftree.py`.

---

## Script

```python
import subprocess
from collections import defaultdict

REPOS = [
    ('monolito',      '/workspace/mnt/estrategia/monolito',      '\033[96m',            '\033[38;5;39m'),
    ('front-student', '/workspace/mnt/estrategia/front-student',  '\033[38;5;213m',      '\033[38;5;198m'),
    ('bo-container',  '/workspace/mnt/estrategia/bo-container',   '\033[38;5;118m',      '\033[38;5;82m'),
]

R        = '\033[0m'
BOLD     = '\033[1m'
GHOST    = '\033[38;5;234m'
DIM      = '\033[38;5;240m'
WIRE     = '\033[38;5;237m'
FNORM    = '\033[38;5;242m'
DNORM    = '\033[38;5;245m'
DANC     = '\033[38;5;141m'
DANC_B   = '\033[1;38;5;183m'
FHIT     = '\033[1;38;5;225m'
FHIT_BG  = '\033[48;5;55m'
STA      = {'M': '\033[38;5;214m', 'A': '\033[38;5;83m', 'D': '\033[38;5;196m'}
SYM      = {'M': '~', 'A': '+', 'D': 'x'}

CHAPTER_KW = ['chapter', 'toc', 'content_tree', 'course_chapter', 'getCourse']

def is_chapter(path): return any(k.lower() in path.lower() for k in CHAPTER_KW)

def build_tree(files):
    tree = {}
    for status, path in files:
        parts = path.split('/')
        node = tree
        for p in parts[:-1]: node = node.setdefault(p, {})
        node.setdefault('__files__', []).append((status, parts[-1], path))
    return tree

def squash(tree):
    result = {}
    for k, v in tree.items():
        if k == '__files__': result[k] = v; continue
        v = squash(v)
        cdirs = [ck for ck in v if ck != '__files__']
        while '__files__' not in v and len(cdirs) == 1:
            ck = cdirs[0]
            k = f'{k}/{ck}'
            v = v[ck]
            v = squash(v)
            cdirs = [ck for ck in v if ck != '__files__']
        result[k] = v
    return result

def has_chapter(tree):
    for s, n, fp in tree.get('__files__', []):
        if is_chapter(fp): return True
    return any(has_chapter(v) for k, v in tree.items() if k != '__files__')

def count_types(tree):
    r = defaultdict(int)
    for s, _, _ in tree.get('__files__', []): r[s] += 1
    for k, v in tree.items():
        if k != '__files__':
            for s, n in count_types(v).items(): r[s] += n
    return r

def stat_str(ct):
    return ' '.join(f'{STA[s]}{SYM[s]}{v}{R}' for s, v in sorted(ct.items()) if v)

def print_tree(tree, gcolor, stack=None):
    if stack is None: stack = []
    files = sorted(tree.get('__files__', []), key=lambda x: x[1])
    dirs  = sorted((k, v) for k, v in tree.items() if k != '__files__')
    items = [('f', x) for x in files] + [('d', x) for x in dirs]

    for idx, (kind, item) in enumerate(items):
        last = idx == len(items) - 1
        brch = '\u2514\u2500 ' if last else '\u251c\u2500 '
        gut  = f'{gcolor}\u2503{R}'
        pad  = ''
        for il in stack:
            pad += '   ' if il else f'{WIRE}\u2502{R}  '
        conn = f'{WIRE}{brch}{R}'

        if kind == 'f':
            status, fname, fullpath = item
            sym = SYM[status]
            if is_chapter(fullpath):
                print(f'{gut}{pad}{conn}{FHIT_BG}{FHIT} {sym} {fname} {R}')
            else:
                print(f'{gut}{pad}{conn}{DIM}{sym}{R} {FNORM}{fname}{R}')
        else:
            dname, subtree = item
            ct  = count_types(subtree)
            n   = sum(ct.values())
            anc = has_chapter(subtree)
            ss  = stat_str(ct)
            if anc:
                dn = f'{DANC_B}{dname}/{R}'
                cn = f'{DANC}({n}){R}'
                mk = f'{DANC}\u25c6{R} '
            else:
                dn = f'{DNORM}{dname}/{R}'
                cn = f'{GHOST}({n}){R}'
                mk = '  '
            print(f'{gut}{pad}{conn}{mk}{dn} {cn} {ss}')
            print_tree(subtree, gcolor, stack + [last])

all_data = []
for name, path, hc, gc in REPOS:
    result = subprocess.run(['git','diff','main...HEAD','--name-status'],
        cwd=path, capture_output=True, text=True)
    files = []
    for line in result.stdout.strip().splitlines():
        p = line.split('\t', 1)
        if len(p) == 2: files.append((p[0], p[1]))
    all_data.append((name, path, hc, gc, files))

total_f = sum(len(d[4]) for d in all_data)
total_a = sum(sum(1 for s,_ in d[4] if s=='A') for d in all_data)
total_m = sum(sum(1 for s,_ in d[4] if s=='M') for d in all_data)
total_d = sum(sum(1 for s,_ in d[4] if s=='D') for d in all_data)
total_h = sum(sum(1 for s,f in d[4] if is_chapter(f)) for d in all_data)

W = 62
print()
print(f'\033[38;5;57m' + '\u2588'*W + R)
print(f'\033[38;5;57m\u2588\u2588{R}\033[1;38;5;225m  DIFF vs main  \033[38;5;57m\u2588\u2588{R}  '
      f'{DIM}{total_f} files{R}  '
      f'{STA["A"]}+{total_a}{R}  {STA["M"]}~{total_m}{R}  {STA["D"]}x{total_d}{R}  '
      f'{DANC}\u25c6 {total_h} chapter{R}')
print(f'\033[38;5;57m' + '\u2588'*W + R)

for name, path, hc, gc, files in all_data:
    ct = defaultdict(int)
    for s, _ in files: ct[s] += 1
    ss = stat_str(ct)
    chapter_count = sum(1 for s,f in files if is_chapter(f))

    print()
    print(f'{hc}\u250f' + '\u2501'*(W-2) + f'\u2513{R}')
    spacer = ' ' * max(0, W - len(name) - 28)
    chap_tag = f'  {DANC}\u25c6{chapter_count} chapter{R}' if chapter_count else ''
    print(f'{hc}\u2503{R} {BOLD}{hc}\u25b6 {name.upper()}{R}  '
          f'{DIM}{len(files)}f{R}  {ss}{chap_tag}{spacer}{hc}\u2503{R}')
    print(f'{hc}\u2517' + '\u2501'*(W-2) + f'\u251b{R}')

    tree = squash(build_tree(files))
    print_tree(tree, gc)

print()
```

---

## Keywords de highlight (atualizar por feature)

O script usa esta lista para identificar arquivos relacionados à feature ativa.
Trocar conforme o dominio em andamento:

```python
CHAPTER_KW = ['chapter', 'toc', 'content_tree', 'course_chapter', 'getCourse']
```

Exemplos de outras features:
- `['payment', 'checkout', 'order']`
- `['enrollment', 'subscription', 'plan']`
- `['trail', 'trilha', 'LDITrail']`

---

## Ideias para evoluir o glance

> Acrescentar aqui conforme surgem nas sessoes

- [ ] **Modo colapsado**: pastas sem highlight ficam fechadas com so o contador,
      expandindo apenas as trilhas que levam aos hits (caberia numa tela so)
- [ ] **Branch info no header**: mostrar nome do branch atual de cada repo
- [ ] **Commits desde main**: quantos commits cada repo tem a frente
- [ ] **Filtro por keyword via argv**: `python3 glance.py payment` troca keywords dinamicamente
- [ ] **Diff inter-repos**: arquivos com mesmo nome em repos diferentes destacados juntos
- [ ] **Timestamp do ultimo commit**: mostrar "ha 2h" no header de cada repo
- [ ] **Worktrees abertas**: listar worktrees ativas de cada repo no header
