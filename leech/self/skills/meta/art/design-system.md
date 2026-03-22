---
name: meta/art/design-system
description: Design system visual do Leech. Palette testada, tokens semanticos, box drawing, regras de desenho, Catppuccin theme, Nerd Font icons. Dividido em TERMINAL (ASCII) e WEB (Chrome relay). Fonte da verdade — ler ANTES de desenhar qualquer coisa.
---

# Design System — Leech

Terminal: Catppuccin Mocha dark, JetBrainsMono Nerd Font.
Browser: Chrome relay via CDP, tema Catppuccin CSS.
Ultima validacao: 2026-03-22.

---

# PARTE 1 — TERMINAL (ASCII)

---

## 1.1 Cores (emojis com cor real)

Terminal renderiza tudo em amber monocromo. Estes emojis sao os UNICOS com cor propria:

### Tokens de cor

| Token | Emoji | Cor real | Hex |
|-------|-------|---------|-----|
| green | 💚 | verde | #a6e3a1 |
| orange | 🧡 | laranja | #fab387 |
| red | 🔴 | vermelho | #f38ba8 |
| blue | 💙 | azul | #89b4fa |
| teal | 🔵 | teal | #94e2d5 |
| orange-sm | 🔶 | laranja | #fab387 |
| blue-sm | 🔷 | azul | #89b4fa |
| orange-xs | 🔸 | laranja peq | #fab387 |
| blue-xs | 🔹 | azul peq | #89b4fa |
| neutral | ⚪ | cinza | #a6adc8 |
| dark | ⬛ | preto | #1e1e2e |
| cross | ❌ | vermelho | #f38ba8 |

### PROIBIDOS (viram listrado/amber)

```
🟢 🟡 🟠 🟣 ✅ ⚠️        circulos/sinais
🟥 🟧 🟨 🟩 🟦 🟪        quadrados
❗ ❓ ⭐ ‼️                sinais sem cor
```

---

## 1.2 Tokens Semanticos

### Status

| Semantica | Emoji |
|-----------|-------|
| ok / passou | 💚 |
| warning | 🧡 |
| blocker / erro | 🔴 |
| pendente | ⚪ |
| info | 🔵 |

### Mudanca (git)

| Semantica | Emoji |
|-----------|-------|
| novo (A) | 💙 |
| modificado (M) | 🔶 |
| removido (D) | ❌ |

### Camadas

| Semantica | Emoji |
|-----------|-------|
| migration/db | 🔹 |
| entity/struct | 🔸 |
| repo | 🔹 |
| service | ⚙️ |
| handler | 🚪 |
| worker | 👷 |
| teste | 🧪 |
| config | 📋 |

### Recursos

| Semantica | Emoji |
|-----------|-------|
| cache (Redis) | ⚡ |
| persist (JSONB) | 💾 |
| fila (SQS) | 📨 |
| guard | 🔒 |

---

## 1.3 Barras de Progresso

8 blocos = 100%. Diamantes coloridos + preto:

```
  💚 completo:   💚💚💚💚💚💚💚💚  100%
  🔷 normal:     🔷🔷🔷🔷🔷⬛⬛⬛   62%
  🔶 atencao:    🔶🔶🔶⬛⬛⬛⬛⬛   37%
  🔴 critico:    🔴🔴⬛⬛⬛⬛⬛⬛   25%
```

Regra: 80-100%→🔷  50-79%→🔶  0-49%→🔴  completo→💚
Monocromo: `████░░░░`

---

## 1.4 Headers

```
══════════════════════════════════════════════════
  TITULO PRINCIPAL
══════════════════════════════════════════════════

── SECAO ────────────────────────────────────────

  conteudo...

─────────────────────────────────────────────────
```

`═` duplo = header principal. `─` com titulo = secao. `─` sem titulo = separador.

---

## 1.5 Box Drawing

### Cheat sheet

```
LIGHT:   ┌─┬─┐  ├─┼─┤  └─┴─┘   │
HEAVY:   ┏━┳━┓  ┣━╋━┫  ┗━┻━┛   ┃
DOUBLE:  ╔═╦═╗  ╠═╬═╣  ╚═╩═╝   ║
ROUNDED: ╭─────╮  ╰─────╯       │  (sem juncoes)
TRANSIT: ┡━━━━━┩  (heavy→light)
```

### Conjuntos (NUNCA misturar pesos)

| Conjunto | Cantos | Linhas | Juncoes | Uso |
|----------|--------|--------|---------|-----|
| Light | `┌┐└┘` | `─ │` | `├┤┬┴┼` | Default — diagramas, tabelas |
| Heavy | `┏┓┗┛` | `━ ┃` | `┣┫┳┻╋` | Headers, destaque |
| Double | `╔╗╚╝` | `═ ║` | `╠╣╦╩╬` | Enfase maxima |
| Rounded | `╭╮╰╯` | `─ │` | nenhuma | Boxes simples |

### Dashed / Dotted

```
┄┄┄┄┄ (dashed)   ┈┈┈┈┈ (dotted)   ⋯⋯⋯⋯⋯ (midline)
```

### Regras de desenho

**R1 — Conjuntos puros.** Cada diagrama usa UM peso. Misturar = gaps.
- Proibido: `╭─╮` com `├┤` (rounded nao tem juncoes)
- Proibido: `┏━┓` header com `│` body (pesos diferentes)
- Excecao: heavy header + light body com `┡┩`:

```
┏━━━━━━━━━━━━━━━━━┓
┃   TITULO        ┃
┡━━━━━━━━━━━━━━━━━┩
│   conteudo      │
└─────────────────┘
```

**R2 — Padding obrigatorio.** Conteudo nunca encosta na borda. Min 1 espaco, 2 preferivel.

```
ERRADO:               CERTO:
┌──────────┐          ┌────────────┐
│conteudo  │          │  conteudo  │
└──────────┘          └────────────┘
```

**R3 — Setas.** Sempre espaco apos a seta.

```
ERRADO: BoxA ──▶BoxB
CERTO:  BoxA ──▶ BoxB ──▶ BoxC
```

**R4 — Multibox.** 5 chars entre boxes. Seta na linha do conteudo.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Modulo A  │ ──▶ │   Modulo B  │ ──▶ │   Modulo C  │
└─────────────┘     └─────────────┘     └─────────────┘
```

**R5 — Sem ZWS.** Zero Width Space (U+200B) causa desalinhamento. So espacos puros.

**R6 — Cruzamentos.** Usar conector correto pro peso. Nunca `+` ou `*`.

```
┌──────┬──────┐
│  A   │  B   │
├──────┼──────┤
│  C   │  D   │
└──────┴──────┘
```

**R7 — NUNCA usar:**

| Caractere | Problema |
|-----------|----------|
| `░▒▓█▀▄▌▐` | Block chars — largura inconsistente |
| `╲╱╳` | Diagonais — nao conectam |
| `-->` `->` `=>` | Parecem codigo, nao diagramas |
| Powerline inline | 2 colunas — desalinha |

---

## 1.6 Setas e Conectores

| Simbolo | Uso |
|---------|-----|
| `→` | Fluxo horizontal simples |
| `──▶` | Chamada para outra funcao |
| `──▷` | Chamada (seta vazia) |
| `──▸` | Seta pequena inline |
| `◄──` | Anotacao apontando algo |
| `▼` | Fluxo continua abaixo |
| `│` | Conexao vertical |
| `├──` | Branch (tem mais abaixo) |
| `└──` | Branch final |
| `──HIT──→` | Resultado cache hit |
| `└─MISS─→` | Resultado cache miss |

### Arrows & Triangles (referencia completa)

```
← → ↑ ↓ ↔ ↕  ◄ ► ▲ ▼  ◁ ▷ △ ▽  ➜ ➤
```

### Bullets & Markers

```
● ○ ◉ ◎  ◆ ◇ ◈  ■ □  ▸ ▹ ◂ ◃  ★ ☆  ✓ ✗ ✔ ✘  ⦿
```

---

## 1.7 Texto e Anotacoes

| Formato | Uso |
|---------|-----|
| `L<N>` | Numero da linha (ex: L45) |
| `[algo]` | Recurso externo entre colchetes |
| `(async)` | Marca operacao assincrona |
| `◄── comentario` | Anotacao lateral |

---

## 1.8 Nerd Font Icons

> Fonte: JetBrainsMono Nerd Font (NAO Mono). Icons ocupam 2 colunas.

```
  terminal       folder        git-branch
  git-merge      gear          gears
  wrench         code          bug
  fire           bolt          rocket
  chip/cpu       server        database
  cloud          lock          unlock
  key            shield        eye
  search         clock         calendar
  bell           bookmark      link
  download       upload        home
  nix/nixos      linux/tux     docker
  github         git
```

---

## 1.9 Banners Dinamicos (bash)

Conteudo dinamico nunca preencher manualmente com espacos. Usar padding:

```bash
pad_line() {
  local border="$1" content="$2" width="${3:-48}"
  local visible; visible=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
  local vlen; vlen=$(echo -n "$visible" | wc -m)
  local pad=$(( width - vlen ))
  [[ $pad -lt 0 ]] && pad=0
  printf '    %s  ' "$border"
  echo -ne "$content"
  printf "%${pad}s%s\n" "" "$border"
}
```

---

## 1.10 Composicao (ordem de montagem)

1. **Header** (`═══`) com titulo, stats, risco
2. **Mini-guia horizontal** (1 linha resumindo o fluxo)
3. **Deep-dive vertical** (caixas expandidas)
4. **Tabelas de status** (checklist, cobertura)
5. **Barras** (risco, proporcao)
6. **Veredito** (blockers, warnings, ok)
7. **Footer** (`═══`)

```
══════════════════════════════════════════════════
  🔍 INSPECAO  FUK2-11746   2026-03-22
  +4981 / -433   117 arquivos
  🧡 Risco: ALTO
══════════════════════════════════════════════════

── 🚪 GET /toc ──────────────────────────────────
  Handler → [⚡cache?] ──HIT──→ Response
                       └─MISS─→ ⚙️ Build → [⚡]+[💾] → Response

── 💚/🔴 CHECKLIST ──────────────────────────────

  💚 ctx propagado (L22)
  🔴 Goroutine sem sync (L38)
  🧡 log.Printf em vez de elogger

── 📊 RISCO ─────────────────────────────────────

  🔹 Migration  🔷🔷🔷🔷🔷🔷🔷🔷  💚
  ⚙️ Service    🔶🔶🔶🔶🔶🔶⬛⬛  🧡
  🚪 Handler    🔴🔴🔴🔴⬛⬛⬛⬛  🔴

── ⚖️ VEREDITO ──────────────────────────────────

  🔴 Blockers: 1    🧡 Warnings: 2    💚 Clean: 8

══════════════════════════════════════════════════
```

---

# PARTE 2 — WEB (Chrome Relay)

---

## 2.1 Tema Catppuccin CSS

```css
:root {
  --ctp-base: #1e1e2e;
  --ctp-mantle: #181825;
  --ctp-crust: #11111b;
  --ctp-surface0: #313244;
  --ctp-surface1: #45475a;
  --ctp-overlay0: #6c7086;
  --ctp-text: #cdd6f4;
  --ctp-subtext0: #a6adc8;
  --ctp-green: #a6e3a1;
  --ctp-blue: #89b4fa;
  --ctp-peach: #fab387;
  --ctp-red: #f38ba8;
  --ctp-mauve: #cba6f7;
  --ctp-yellow: #f9e2af;
  --ctp-teal: #94e2d5;
}
body {
  background: var(--ctp-base);
  color: var(--ctp-text);
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
}
```

## 2.2 Cores semanticas no Chrome

| Semantica | Cor | Var CSS | Hex |
|-----------|-----|---------|-----|
| Novo / sucesso | verde | --ctp-green | #a6e3a1 |
| Cache / info | azul | --ctp-blue | #89b4fa |
| Trigger / warning | laranja | --ctp-peach | #fab387 |
| Erro / blocker | vermelho | --ctp-red | #f38ba8 |
| Destaque / titulo | roxo | --ctp-mauve | #cba6f7 |
| Fundo primario | dark | --ctp-base | #1e1e2e |
| Fundo secundario | darker | --ctp-mantle | #181825 |
| Bordas | gray | --ctp-surface0 | #313244 |
| Texto | white | --ctp-text | #cdd6f4 |

## 2.3 Mermaid Theme

Para diagramas Mermaid no Chrome, usar themeVariables:

```javascript
%%{init: {'theme': 'base', 'themeVariables': {
  'primaryColor': '#313244',
  'primaryTextColor': '#cdd6f4',
  'primaryBorderColor': '#45475a',
  'lineColor': '#6c7086',
  'secondaryColor': '#181825',
  'tertiaryColor': '#11111b',
  'background': '#1e1e2e',
  'mainBkg': '#313244',
  'nodeBorder': '#45475a',
  'clusterBkg': '#181825',
  'titleColor': '#cdd6f4',
  'edgeLabelBackground': '#1e1e2e'
}}}%%
```

Cores de nos:
- Novo: `fill:#a6e3a1,color:#1e1e2e`
- Cache: `fill:#89b4fa,color:#1e1e2e`
- Trigger: `fill:#fab387,color:#1e1e2e`
- Erro: `fill:#f38ba8,color:#1e1e2e`

## 2.4 Como servir HTML

```bash
# Gerar HTML em /tmp/page.html
HTML_B64=$(base64 -w 0 /tmp/page.html)
python3 /workspace/self/scripts/chrome-relay.py nav "data:text/html;base64,${HTML_B64}"
```

Templates HTML completos:
- Mermaid flowchart: `code/analysis/flows/templates/html.md`
- Arvore interativa: `code/analysis/diff/templates/interactive-tree.html`
