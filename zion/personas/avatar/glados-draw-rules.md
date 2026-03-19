# Regras de Desenho para Diagramas

> Contexto: Claude Code CLI rodando dentro de Alacritty com JetBrainsMono Nerd Font.
> Alacritty tem `builtin_box_drawing = true` — box-drawing é renderizado pela Alacritty diretamente.
> MAS o renderer do Claude Code adiciona sua própria camada (markdown + monospace code blocks) que pode
> introduzir micro-gaps entre caracteres se o conjunto de caracteres misturar pesos ou estilos.

### Regra 1 — Usar conjuntos puros, nunca misturar pesos

Cada diagrama deve usar UM conjunto de box-drawing de ponta a ponta. Misturar pesos causa gaps nas junções.

| Conjunto | Cantos | Linhas H/V | Junções | Uso recomendado |
|----------|--------|------------|---------|-----------------|
| Light    | `┌┐└┘` | `─ │`      | `├┤┬┴┼` | Diagramas gerais, corpo de tabelas |
| Rounded  | `╭╮╰╯` | `─ │`      | (sem junções nativas) | Boxes simples sem T-junctions |
| Heavy    | `┏┓┗┛` | `━ ┃`      | `┣┫┳┻╋` | Headers, destaque, seção principal |
| Double   | `╔╗╚╝` | `═ ║`      | `╠╣╦╩╬` | Ênfase máxima, títulos |

**Proibido:** `╭─╮` combinado com `├` ou `┬` — rounded não tem junções, misturar com light cria gaps.
**Proibido:** `┏━┓` no header com `│` light no corpo — pesos diferentes = desalinhamento vertical.

**Exceção permitida:** `heavy header + light body` usando os conectores de transição `┡┩` (U+2521/U+2529):
```
┏━━━━━━━━━━━━━━━━━┓
┃   TÍTULO        ┃
┡━━━━━━━━━━━━━━━━━┩
│   conteúdo      │
└─────────────────┘
```
`┡` (U+2521) e `┩` (U+2529) são os conectores explícitos heavy-to-light — usá-los SEMPRE nesse padrão.

### Regra 2 — Padding interno obrigatório

Conteúdo nunca deve encostar na borda. Mínimo de **1 espaço** em cada lado, **2 espaços** preferível.

```
ERRADO:                    CERTO:
┌──────────┐               ┌────────────┐
│conteúdo  │               │  conteúdo  │
└──────────┘               └────────────┘
```

Para linhas de separação horizontal dentro de uma box:
```
├──────────┤   ← CERTO: borda esquerda + linha + borda direita, sem espaços entre
```

### Regra 3 — Arrows entre boxes

**Usar apenas:**
- `──▶` ou `──▷` para fluxo horizontal (seta preenchida ou vazia)
- `──▸` para seta pequena inline
- `→` para referências simples (sem linha)
- `──►` (hífen ASCII) apenas dentro de code blocks onde monospace é garantido

**Evitar:**
- `──▼` ou `──▲` em linha horizontal — triângulos verticais em contexto horizontal causam gap visual
- `──►` sem espaço antes: a largura do `►` (U+25BA) é 1 coluna mas pode variar — sempre testar
- Não usar `-->` ou `->` em diagramas — ambíguo, parece Markdown/pseudo-código

**Regra de espaçamento com arrows:**
```
ERRADO: BoxA ──▶BoxB       (arrow colado no texto de destino)
CERTO:  BoxA ──▶ BoxB      (espaço após a seta)
CERTO:  BoxA ──▶ BoxB ──▶ BoxC
```

### Regra 4 — Diagrama de fluxo multibox: template

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Módulo A  │ ──▶ │   Módulo B  │ ──▶ │   Módulo C  │
└─────────────┘     └─────────────┘     └─────────────┘
```

Regras desse template:
- Espaço de **5 chars** entre boxes (`     `) — dá espaço pra seta `──▶` + 1 espaço de cada lado
- Conteúdo interno com **3 espaços** de padding cada lado
- Todas as linhas horizontais do mesmo comprimento (alinhar visualmente antes de digitar)
- A linha de conexão fica na **linha do meio** da box (onde está o conteúdo, não nas bordas)

### Regra 5 — NÃO usar ZWS em code blocks

ZWS (U+200B) foi testado e CAUSA desalinhamento no box-drawing dentro do terminal Claude Code.
Usar espaços puros para todo padding e indentação em code blocks.

Testado em 2026-03-14: avatar com ZWS ficava com caixa externa desalinhada da interna.
Sem ZWS, usando apenas espaços, renderiza perfeitamente.

### Regra 6 — Conectores T e cruzamentos

Para dividir uma box em seções:
```
┌─────────────┐
│   Seção 1   │
├─────────────┤   ← T horizontal: └ + ─ + ┘ viram ├ + ─ + ┤
│   Seção 2   │
└─────────────┘
```

Para cruzamentos em grades:
```
┌──────┬──────┐
│  A   │  B   │
├──────┼──────┤   ← cruzamento = ┼ (nunca sobrepor + ou *)
│  C   │  D   │
└──────┴──────┘
```

**Regra crítica dos cruzamentos:** usar SEMPRE o conector correto para o peso.
- Light: `┼ ├ ┤ ┬ ┴`
- Heavy: `╋ ┣ ┫ ┳ ┻`
- Double: `╬ ╠ ╣ ╦ ╩`
Nunca substituir por `+`, `*` ou espaço — cria gap visual.

### Regra 7 — O que NUNCA usar em diagramas

| Caractere | Problema |
|-----------|----------|
| `░ ▒ ▓ █ ▀ ▄ ▌ ▐` | Block chars — largura inconsistente nesta fonte |
| `╲ ╱ ╳` | Diagonais — não conectam com nada |
| `╭╮╰╯` + junções `├┤┬┴┼` | Rounded não tem junções — cria gap |
| Mixed weights sem connector | Ex: `┏` + `│` — gap na linha vertical |
| Setas Nerd Font Powerline inline | Ocupam 2 colunas — desalinham tudo ao redor |

### Referência rápida — Cheat Sheet

```
LIGHT:   ┌─┬─┐  ├─┼─┤  └─┴─┘   │
HEAVY:   ┏━┳━┓  ┣━╋━┫  ┗━┻━┛   ┃
DOUBLE:  ╔═╦═╗  ╠═╬═╣  ╚═╩═╝   ║
ROUNDED: ╭─────╮  ╰─────╯       │  (sem junções)
TRANSIT: ┡━━━━━┩  (heavy→light top) ╞═════╡ (double→light)

ARROWS:  ──▶  ──▷  ──▸  →  ↑  ↓  ←
AVOID:   --> -> => => ~~> (parecem código, não diagramas)
```
