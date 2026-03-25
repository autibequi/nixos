---
name: meta/skill/explain
description: Explica qualquer skill visualmente — gera flowchart Mermaid no holodeck mostrando gatilhos, sub-skills invocadas, decisoes e entregavel final.
---

# /meta:skill:explain — Explicar uma Skill Visualmente

> Dado o nome de uma skill, lê sua documentação e gera um flowchart interativo no holodeck.
> Objetivo: entender de uma vez como a skill funciona, sem ler parágrafos.

---

## Uso

```
/meta:skill:explain <nome-da-skill>

Exemplos:
  /meta:skill:explain thinking
  /meta:skill:explain code/debug
  /meta:skill:explain estrategia/jira
```

---

## Fluxo interno

### 1. Ler a skill alvo

```bash
# Localizar o SKILL.md
Glob: /workspace/self/skills/<nome>/**/*.md

# Ler principal + sub-skills listadas
Read: SKILL.md da skill
Read: sub-skills mencionadas (se existirem)
```

### 2. Extrair estrutura

Do SKILL.md, identificar:

| O que extrair | Onde encontrar |
|---|---|
| **Gatilhos** | Seção "Quando usar", "Gatilhos", frontmatter description |
| **Sub-skills invocadas** | Tabela de sub-skills, menções a `→ invocar X` |
| **Decisões** | Lógica condicional: "se X → Y", forks documentados |
| **Output / entregável** | O que a skill produz ao final |
| **Agentes envolvidos** | Menções a `Agent tool`, `subagent_type`, nomes de agentes |

### 3. Gerar o diagrama Mermaid

**Estrutura base:**

```
flowchart TD
  START([gatilho de entrada]) --> FASE1

  subgraph FASE1["Nome da fase"]
    STEP1["ação 1"]
    ...
  end

  STEP_N --> DECIDE{decisão?}
  DECIDE -->|sim| SUB_SKILL_A["🤖 sub-skill A"]
  DECIDE -->|não| SUB_SKILL_B["ação B"]

  SUB_SKILL_A & SUB_SKILL_B --> END_NODE
  END_NODE(((entregavel)))
```

**Regras de estilo (Catppuccin):**

```
Gatilho / fim     → fill:#cba6f7,color:#1e1e2e   (roxo)
Agente invocado   → fill:#fab387,color:#1e1e2e   (laranja)
Artefato / dado   → fill:#313244,color:#cdd6f4   (cinza)
Entregavel final  → fill:#f9e2af,color:#1e1e2e   (dourado)
Erro / fallback   → fill:#f38ba8,color:#1e1e2e   (vermelho)
```

**Símbolos:**
- `([texto])` — início/fim (stadium)
- `["texto"]` — processo
- `{"texto"}` — decisão
- `(((texto)))` — objetivo final (círculo duplo)
- `🤖` — agente invocado (Coruja, Claude subagente, etc.)

### 4. Preencher o template

Template base: `/workspace/self/skills/meta/holodeck/templates/mermaid.html`

**Três placeholders a substituir:**

| Placeholder | O que colocar |
|---|---|
| `MERMAID_DIAGRAM_HERE` | Conteúdo do diagrama (sem as crases do bloco) |
| `LEGEND_ITEMS_HERE` | Linhas HTML da legenda (ver formato abaixo) |
| `RAW_MERMAID_SOURCE` | Source do diagrama como string JS (escapar aspas com `\"`) |
| `RAW_DIAGRAM_TITLE` | Nome da skill explicada |

**Formato das linhas de legenda:**

```html
  <div class="leg-row"><span class="leg-dot c-purple">◉</span> início / fim</div>
  <div class="leg-row"><span class="leg-dot">▭</span> processo</div>
  <div class="leg-row"><span class="leg-dot">◇</span> decisão</div>
  <div class="leg-row"><span class="leg-dot c-orange">🤖</span> agente invocado</div>
  <div class="leg-row"><span class="leg-dot c-yellow">◎</span> entregável final</div>
```

**Classes de cor disponíveis:** `c-purple`, `c-orange`, `c-blue`, `c-yellow`, `c-dim`

### 5. Servir no holodeck

```python
# Salvar o HTML gerado
with open('/tmp/chrome-relay/<skill-name>-explain.html', 'w') as f:
    f.write(html)

# Abrir no Chrome
python3 /workspace/self/scripts/chrome-relay.py nav "http://leech:8765/<skill-name>-explain.html"
```

---

## Referência de output

O diagrama `/workspace/obsidian/vault/diagrams/skill-flow-jira.md` é o exemplo de qualidade:

- Fases agrupadas em `subgraph`
- Agentes com `🤖`, decisões com `{}`, artefatos com emojis de dado
- Nó final `(((objetivo cumprido)))` dourado
- Legenda no canto inferior direito via overlay HTML
- Botão "ver código Mermaid" no topo da legenda

Gerar HTML via script Python (não manualmente):

```python
import re, json

with open('/workspace/self/skills/meta/holodeck/templates/mermaid.html') as f:
    template = f.read()

diagram  = "... conteudo mermaid ..."
title    = "nome-da-skill"
legend   = "... linhas HTML da legenda ..."

html = (template
    .replace('MERMAID_DIAGRAM_HERE', diagram)
    .replace('LEGEND_ITEMS_HERE',    legend)
    .replace('RAW_MERMAID_SOURCE',   diagram.replace('"', '\\"').replace('\n', '\\n'))
    .replace('RAW_DIAGRAM_TITLE',    title))
```

---

## Anti-patterns

| Errado | Certo |
|---|---|
| Mostrar apenas ASCII no terminal | Usar sempre o holodeck — o ponto é ver o diagrama |
| Gerar um nó por linha do SKILL.md | Agrupar por fase/responsabilidade — menos nós, mais claro |
| Omitir agentes invocados | Sempre indicar com 🤖 quando há Agent tool call |
| Diagrama sem nó final | Sempre terminar com `(((entregavel)))` dourado |
