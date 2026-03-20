"""
code/analysis/diff — Gerador de diff interativo para o Chrome.

Uso:
    1. Salvar o diff em /tmp/<repo>_diff.txt:
           cd /home/claude/projects/estrategia/<REPO>/
           git diff origin/main --name-status > /tmp/<repo>_diff.txt

    2. Preencher DESCRIPTIONS (ver seção abaixo) com (tag, detail) por arquivo.
       tag    = o que foi feito (curto, ex: "novo endpoint GET /toc")
       detail = o porquê (mais longo, ex: "retorna flat sem dados pesados")

    3. Ajustar CHAPTER_KW para a feature ativa (arquivos ficam roxos na árvore).

    4. Rodar:
           python3 generator.py > /dev/null
       O HTML puro é salvo em /tmp/<REPO>_diff_annotated.html.

    5. Abrir no Chrome via relay:
           python3 - << 'EOF'
           import sys, base64, time
           with open('/tmp/<REPO>_diff_annotated.html', 'rb') as f:
               html = f.read().decode()
           sys.argv = ['chrome-relay.py', 'nav', 'about:blank']
           exec(open('/workspace/zion/scripts/chrome-relay.py').read())
           EOF

           python3 - << 'EOF'
           import sys, base64, time; time.sleep(0.4)
           with open('/tmp/<REPO>_diff_annotated.html', 'rb') as f:
               html = f.read().decode()
           js = "document.open();document.write(atob('" + base64.b64encode(html.encode()).decode() + "'));document.close();"
           sys.argv = ['chrome-relay.py', 'inject', js]
           exec(open('/workspace/zion/scripts/chrome-relay.py').read())
           EOF

Funcionalidades do viewer:
    - Pastas colapsáveis (clique → fecha/abre com animação)
    - Clique num arquivo → ancestor glow (todos os dirs pai brilham em azul)
    - Path bar sticky no topo (abaixo do header): mostra path + tag + detail
    - Anotações dim por linha: // tag  (ciano escuro, opacity 0.45, coluna fixa)
    - Ícone copy (SVG) ao lado esquerdo do nome: copia path relativo para clipboard
    - Keywords da feature destacadas em roxo (◆) nas pastas/arquivos
    - Tema Catppuccin Mocha dark, sempre
"""

import base64
from collections import defaultdict

# ── Configuração ──────────────────────────────────────────────────────────────

REPO        = 'monolito'
BRANCH      = 'FUK2-11746-vibed/cached-ldi-toc'
DIFF_FILE   = '/tmp/mono_diff.txt'
OUTPUT_FILE = '/tmp/mono_diff_annotated.html'

# Keywords que ficam em roxo na árvore (arquivos da feature ativa)
CHAPTER_KW = ['chapter', 'toc', 'content_tree', 'course_chapter', 'getCourse']

# Descrições por arquivo: 'path/relativo' -> ('tag curta', 'detalhe longo')
# tag    = aparece inline na linha (dim cyan) e no pathbar (teal bold)
# detail = só aparece no pathbar ao selecionar o arquivo
DESCRIPTIONS = {
    # Exemplo de preenchimento:
    # 'apps/bff/internal/handlers/main/ldi/get_course_structure.go':
    #     ('novo endpoint GET /toc',
    #      'retorna estrutura flat (chapters+items+has_blocks) sem dados pesados de progresso/favoritos'),
}

# ── Lógica da árvore ─────────────────────────────────────────────────────────

def is_chapter(path):
    return any(k.lower() in path.lower() for k in CHAPTER_KW)

def build_tree(files):
    tree = {}
    for status, path in files:
        parts = path.split('/')
        node = tree
        for p in parts[:-1]:
            node = node.setdefault(p, {})
        node.setdefault('__files__', []).append((status, parts[-1], path))
    return tree

def squash(tree):
    result = {}
    for k, v in tree.items():
        if k == '__files__':
            result[k] = v
            continue
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

def count_types(tree):
    r = defaultdict(int)
    for s, _, _ in tree.get('__files__', []):
        r[s] += 1
    for k, v in tree.items():
        if k != '__files__':
            for s, n in count_types(v).items():
                r[s] += n
    return r

def has_chapter_tree(tree):
    for s, n, fp in tree.get('__files__', []):
        if is_chapter(fp):
            return True
    return any(has_chapter_tree(v) for k, v in tree.items() if k != '__files__')

STATUS_COLOR = {'M': '#fab387', 'A': '#a6e3a1', 'D': '#f38ba8'}
STATUS_SYM   = {'M': '~', 'A': '+', 'D': '×'}
_node_id = [0]

COPY_ICON = (
    '<svg class="copy-icon" onclick="event.stopPropagation();copyFilePath(this)" '
    'viewBox="0 0 16 16" width="13" height="13" fill="currentColor" title="copy path">'
    '<path d="M4 2h7a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1zm0 1v9h7V3H4z"/>'
    '<path d="M2 4v9a1 1 0 0 0 1 1h8v-1H3V4H2z"/>'
    '</svg>'
)

def render_tree_html(tree, path_prefix=''):
    html = ''
    files = sorted(tree.get('__files__', []), key=lambda x: x[1])
    dirs  = sorted((k, v) for k, v in tree.items() if k != '__files__')
    items = [('f', x) for x in files] + [('d', x) for x in dirs]

    for idx, (kind, item) in enumerate(items):
        last = idx == len(items) - 1
        conn = '└─' if last else '├─'

        if kind == 'f':
            status, fname, fullpath = item
            sym   = STATUS_SYM[status]
            color = STATUS_COLOR[status]
            ch    = 'chapter-hit' if is_chapter(fullpath) else ''
            fcls  = 'fname chapter' if is_chapter(fullpath) else 'fname'

            desc   = DESCRIPTIONS.get(fullpath, ('', ''))
            tag    = desc[0] if desc[0] else ''
            detail = desc[1] if desc[1] else ''
            tag_html    = f'<span class="desc-tag">{tag}</span>' if tag else ''
            detail_html = f'<span class="desc-detail">{detail}</span>' if detail else ''

            html += (
                f'<div class="tree-line file-node {ch}" data-path="{fullpath}" onclick="selectFile(this)">'
                f'<span class="connector">{conn} </span>'
                f'<span class="sym" style="color:{color}">{sym}</span> '
                f'{COPY_ICON}'
                f'<span class="{fcls}">{fname}</span>'
                f'{tag_html}{detail_html}'
                f'</div>\n'
            )
        else:
            dname, subtree = item
            ct    = count_types(subtree)
            total = sum(ct.values())
            anc   = has_chapter_tree(subtree)
            stats = ''.join(
                f'<span style="color:{STATUS_COLOR[s]}">{STATUS_SYM[s]}{n}</span> '
                for s, n in sorted(ct.items()) if n
            )
            full_dir = f'{path_prefix}/{dname}' if path_prefix else dname
            nid  = f'dir-{_node_id[0]}'
            _node_id[0] += 1
            dcls    = 'dirname chapter-dir' if anc else 'dirname'
            diamond = '<span class="diamond">◆</span> ' if anc else ''
            html += (
                f'<div class="tree-line dir-node" data-dir="{full_dir}" data-target="{nid}" onclick="toggleDir(this)">'
                f'<span class="connector">{conn} </span>'
                f'<span class="collapse-arrow">▾</span> '
                f'{diamond}<span class="{dcls}">{dname}/</span> '
                f'<span class="count">({total})</span> {stats}'
                f'</div>\n'
                f'<div class="subtree" id="{nid}">\n'
            )
            html += render_tree_html(subtree, full_dir)
            html += '</div>\n'

    return html

# ── Leitura do diff ───────────────────────────────────────────────────────────

files = []
with open(DIFF_FILE) as f:
    for line in f:
        parts = line.strip().split('\t', 1)
        if len(parts) == 2:
            files.append((parts[0], parts[1]))

total_a  = sum(1 for s, _ in files if s == 'A')
total_m  = sum(1 for s, _ in files if s == 'M')
total_d  = sum(1 for s, _ in files if s == 'D')
total_ch = sum(1 for s, p in files if is_chapter(p))

_node_id[0] = 0
tree_html = render_tree_html(squash(build_tree(files)))

# ── HTML ─────────────────────────────────────────────────────────────────────

html = f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Diff — {REPO} — {BRANCH}</title>
<style>
:root {{
  --ctp-base:    #1e1e2e; --ctp-mantle:  #181825; --ctp-crust:   #11111b;
  --ctp-surface0:#313244; --ctp-surface1:#45475a; --ctp-overlay0:#6c7086;
  --ctp-text:    #cdd6f4; --ctp-subtext0:#a6adc8;
  --ctp-green:   #a6e3a1; --ctp-peach:   #fab387; --ctp-red:     #f38ba8;
  --ctp-mauve:   #cba6f7; --ctp-lavender:#b4befe; --ctp-sapphire:#74c7ec;
  --ctp-teal:    #94e2d5; --ctp-yellow:  #f9e2af;
}}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{
  background: var(--ctp-base); color: var(--ctp-text);
  font-family: 'JetBrains Mono', 'Fira Code', 'Cascadia Code', monospace;
  font-size: 13px; min-height: 100vh; padding-bottom: 4rem;
}}

/* ── Header ── */
.header {{
  background: var(--ctp-mantle); border-bottom: 2px solid var(--ctp-surface1);
  padding: 1.1rem 2rem; display: flex; align-items: center; gap: 1.2rem;
  flex-wrap: wrap; position: sticky; top: 0; z-index: 100;
}}
.header-title {{ font-size: 0.9rem; color: var(--ctp-mauve); font-weight: bold; letter-spacing: 0.1em; text-transform: uppercase; }}
.repo-badge {{ background: var(--ctp-sapphire); color: var(--ctp-crust); padding: 0.15rem 0.7rem; border-radius: 4px; font-weight: bold; font-size: 0.8rem; }}
.branch-badge {{ background: var(--ctp-surface0); color: var(--ctp-green); padding: 0.15rem 0.7rem; border-radius: 4px; font-size: 0.8rem; }}
.stats {{ display: flex; gap: 1rem; margin-left: auto; align-items: center; }}
.stat {{ font-size: 0.82rem; }}
.chapter-count {{ background: rgba(203,166,247,0.12); color: var(--ctp-mauve); padding: 0.15rem 0.6rem; border-radius: 4px; font-size: 0.8rem; }}

/* ── Path bar (sticky top, below header) ── */
#pathbar {{
  position: sticky; top: 56px; z-index: 99;
  background: rgba(17,17,27,0.97); border-bottom: 1px solid var(--ctp-surface0);
  padding: 0.5rem 1.8rem 0.55rem; display: flex; flex-direction: column;
  gap: 0.18rem; font-size: 0.8rem; min-height: 2.4rem;
  backdrop-filter: blur(4px); transition: border-color 0.15s;
}}
#pathbar.has-path {{ border-bottom-color: var(--ctp-surface1); }}
#pathbar .bc-empty {{ color: var(--ctp-surface1); font-style: italic; font-size: 0.75rem; line-height: 2; }}
#pathbar .path-row {{ display: flex; align-items: center; white-space: nowrap; overflow: hidden; }}
#pathbar .bc-sep {{ color: var(--ctp-surface1); margin: 0 0.3rem; user-select: none; }}
#pathbar .bc-dir {{ color: var(--ctp-overlay0); }}
#pathbar .bc-file {{ color: var(--ctp-text); font-weight: bold; }}
#pathbar .info-row {{ display: flex; align-items: baseline; gap: 0.5rem; }}
#pathbar .bc-tag {{ color: var(--ctp-teal); font-size: 0.8rem; font-weight: 600; white-space: nowrap; }}
#pathbar .bc-detail {{ color: var(--ctp-subtext0); font-size: 0.76rem; font-style: italic; opacity: 0.8; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }}

/* ── Tree ── */
.tree-container {{ padding: 1.2rem 1.5rem 1.2rem 1.8rem; line-height: 2; user-select: none; }}
.subtree {{
  padding-left: 1.4rem; border-left: 1px solid var(--ctp-surface0);
  margin-left: 0.5rem; overflow: hidden;
  transition: max-height 0.22s cubic-bezier(0.4,0,0.2,1), opacity 0.18s ease;
  max-height: 9999px; opacity: 1;
}}
.subtree.collapsed {{ max-height: 0 !important; opacity: 0; pointer-events: none; }}
.tree-line {{
  display: flex; align-items: center; white-space: nowrap;
  padding: 0.05rem 0.3rem; border-radius: 4px; transition: background 0.12s; position: relative;
}}
.tree-line:hover {{
  background: linear-gradient(90deg, rgba(116,199,236,0.07) 0%, rgba(116,199,236,0.015) 100%);
  box-shadow: inset 2px 0 0 rgba(116,199,236,0.35);
}}
.tree-line:hover .desc-tag {{ opacity: 0.75; }}

.connector {{ color: var(--ctp-surface1); margin-right: 0.3rem; letter-spacing: -1px; flex-shrink: 0; }}
.sym {{ font-weight: bold; width: 1.3em; display: inline-block; margin-right: 0.2rem; flex-shrink: 0; }}
.fname {{ color: var(--ctp-subtext0); flex-shrink: 0; }}
.dirname {{ color: var(--ctp-lavender); font-weight: 500; }}
.count {{ color: var(--ctp-overlay0); font-size: 0.82em; margin-left: 0.3rem; }}
.chapter-dir {{ color: var(--ctp-mauve); font-weight: bold; }}
.diamond {{ color: var(--ctp-mauve); margin-right: 0.1rem; }}
.collapse-arrow {{
  font-size: 0.75rem; color: var(--ctp-overlay0); display: inline-block;
  transition: transform 0.18s ease; margin-right: 0.2rem; width: 1em; flex-shrink: 0;
}}
.dir-node {{ cursor: pointer; }}
.dir-node.collapsed-dir .collapse-arrow {{ transform: rotate(-90deg); }}
.dir-node.collapsed-dir .dirname {{ opacity: 0.6; }}
.chapter-hit {{ background: rgba(203,166,247,0.05); border-left: 2px solid rgba(203,166,247,0.4); padding-left: 2px; }}
.chapter {{ color: var(--ctp-text); font-weight: 600; }}

/* ── Inline annotations (dim cyan, fixed column) ── */
.desc-detail {{ display: none; }}
.desc-tag {{
  position: absolute; left: 460px;
  color: #4a9a8a; font-size: 0.76rem; opacity: 0.45;
  white-space: nowrap; pointer-events: none; letter-spacing: 0.01em;
}}
.desc-tag::before {{ content: '// '; color: #3a6a60; }}
.file-node:hover .desc-tag {{ opacity: 0.75; }}
.file-node.selected .desc-tag {{ opacity: 0.9; color: var(--ctp-teal); }}

/* ── Copy icon (inline, appears on hover) ── */
.copy-icon {{
  display: inline-flex; align-items: center; justify-content: center;
  width: 1.1rem; height: 1.1rem; margin-right: 0.3rem;
  cursor: pointer; opacity: 0; transition: opacity 0.12s;
  flex-shrink: 0; color: var(--ctp-overlay0); border-radius: 3px;
}}
.copy-icon:hover {{ color: var(--ctp-sapphire); background: rgba(116,199,236,0.15); }}
.copy-icon.flash {{ color: var(--ctp-green) !important; opacity: 1 !important; }}
.file-node:hover .copy-icon {{ opacity: 0.6; }}
.file-node.selected .copy-icon {{ opacity: 0.7; }}

/* ── Selection + ancestor glow ── */
.file-node {{ cursor: pointer; }}
.file-node.selected {{ background: rgba(116,199,236,0.12) !important; }}
.file-node.selected .fname {{ color: var(--ctp-sapphire) !important; font-weight: bold; }}
.dir-node.ancestor-glow {{ background: rgba(116,199,236,0.07); }}
.dir-node.ancestor-glow .dirname {{ color: var(--ctp-sapphire) !important; text-shadow: 0 0 12px rgba(116,199,236,0.5); }}
.dir-node.ancestor-glow .connector {{ color: rgba(116,199,236,0.5) !important; }}
.subtree.ancestor-glow-branch {{ border-left-color: rgba(116,199,236,0.4) !important; }}

/* ── Legend ── */
.legend {{
  display: flex; gap: 1.5rem; padding: 0.6rem 2rem;
  background: var(--ctp-mantle); border-top: 1px solid var(--ctp-surface0);
  margin-top: 1rem; font-size: 0.78rem; color: var(--ctp-overlay0);
}}
.leg {{ display: flex; align-items: center; gap: 0.4rem; }}
.leg-dot {{ width: 10px; height: 10px; border-radius: 2px; }}
</style>
</head>
<body>

<div class="header">
  <span class="header-title">DIFF</span>
  <span class="repo-badge">{REPO}</span>
  <span class="branch-badge">{BRANCH}</span>
  <div class="stats">
    <span class="stat" style="color:var(--ctp-text)">{len(files)} files</span>
    <span class="stat" style="color:#a6e3a1">+{total_a} novos</span>
    <span class="stat" style="color:#fab387">~{total_m} mod</span>
    <span class="stat" style="color:#f38ba8">×{total_d} del</span>
    <span class="chapter-count">◆ {total_ch} feature</span>
  </div>
</div>

<div id="pathbar">
  <span class="bc-empty">clique em um arquivo para ver o caminho</span>
</div>

<div class="tree-container" id="tree-root">
{tree_html}
</div>

<div class="legend">
  <div class="leg"><div class="leg-dot" style="background:#a6e3a1"></div>novo (+)</div>
  <div class="leg"><div class="leg-dot" style="background:#fab387"></div>modificado (~)</div>
  <div class="leg"><div class="leg-dot" style="background:#f38ba8"></div>deletado (×)</div>
  <div class="leg" style="color:var(--ctp-mauve)">◆ feature keywords</div>
  <div class="leg" style="margin-left:auto; color:var(--ctp-overlay0)">clique pasta = colapsar · clique arquivo = trilha</div>
</div>

<script>
function toggleDir(dirEl) {{
  const sub = document.getElementById(dirEl.dataset.target);
  if (!sub) return;
  sub.classList.toggle('collapsed', !sub.classList.contains('collapsed'));
  dirEl.classList.toggle('collapsed-dir', !dirEl.classList.contains('collapsed-dir'));
}}

let lastSelected = null;

function selectFile(fileEl) {{
  if (lastSelected) lastSelected.classList.remove('selected');
  document.querySelectorAll('.ancestor-glow').forEach(el => el.classList.remove('ancestor-glow'));
  document.querySelectorAll('.ancestor-glow-branch').forEach(el => el.classList.remove('ancestor-glow-branch'));
  fileEl.classList.add('selected');
  lastSelected = fileEl;

  const fullPath = fileEl.dataset.path;
  const parts = fullPath.split('/');
  const fname = parts[parts.length - 1];
  const pathbar = document.getElementById('pathbar');

  let pathRow = '<div class="path-row">';
  pathRow += parts.slice(0,-1).map(d => `<span class="bc-dir">${{d}}</span><span class="bc-sep">/</span>`).join('');
  pathRow += `<span class="bc-file">${{fname}}</span></div>`;

  const tagEl    = fileEl.querySelector('.desc-tag');
  const detailEl = fileEl.querySelector('.desc-detail');
  const tagText    = tagEl    ? tagEl.textContent.replace(/^\\/\\/\\s*/, '').trim() : '';
  const detailText = detailEl ? detailEl.textContent.replace(/^·\\s*/, '').trim()   : '';
  let infoRow = '';
  if (tagText || detailText) {{
    infoRow = '<div class="info-row">';
    if (tagText)    infoRow += `<span class="bc-tag">${{tagText}}</span>`;
    if (detailText) infoRow += `<span class="bc-detail">${{detailText}}</span>`;
    infoRow += '</div>';
  }}
  pathbar.innerHTML = pathRow + infoRow;
  pathbar.classList.add('has-path');

  let node = fileEl.parentElement;
  while (node && node.id !== 'tree-root') {{
    if (node.classList.contains('subtree')) {{
      node.classList.add('ancestor-glow-branch');
      const d = node.previousElementSibling;
      if (d && d.classList.contains('dir-node')) d.classList.add('ancestor-glow');
    }}
    node = node.parentElement;
  }}
}}

function copyFilePath(iconEl) {{
  const path = iconEl.closest('.file-node').dataset.path;
  navigator.clipboard.writeText(path).then(() => {{
    iconEl.classList.add('flash');
    setTimeout(() => iconEl.classList.remove('flash'), 1200);
  }});
}}
</script>
</body>
</html>"""

with open(OUTPUT_FILE, 'w') as f:
    f.write(html)

b64 = base64.b64encode(html.encode()).decode()
print(f"data:text/html;base64,{b64}")
