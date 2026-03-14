# Claude Code Statusline Configuration

## Overview
Dois modos de statusline disponíveis para Claude Code:

### 1. Statusline Padrão (Detalhado)
**Arquivo:** `~/.claude/statusline.sh`

Mostra informações completas em uma linha:
```
[session] topic... | Model 42%% | W:1 R:3
```

**Elementos:**
- `[session]` — Session ID (cyan)
- `topic...` — Tópico extraído da última mensagem do user (truncado a 40 chars)
- `Model` — Nome completo do modelo (ex: "Opus 4.6")
- `42%%` — Context window usado (%)
- `W:1 R:3` — Workers ativos e tasks em andamento

**Ideal para:** Rastreamento detalhado durante sessões interativas

---

### 2. Statusline Compacto (Emoji)
**Arquivo:** `~/.claude/statusline-compact.sh`

Oneliner minimalista com emojis:
```
🔌[session] | 🧠opi | 📊42% | W:1 R:3
```

**Elementos:**
- `🔌[session]` — Session ID com ícone de conexão (ou `🔌[~]` se vazio)
- `🧠` — Ícone de cérebro (modelo)
- `opi` — Shorthand do modelo (primeiras 3 letras em lowercase)
- `📊42%` — Context window com gráfico
- `W:1 R:3` — Workers e tasks

**Ideal para:** Sessões autônomas, visual compacto

---

## Como Aplicar

### Opção A: via `settings.json`
Edite `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-compact.sh"
  }
}
```

Escolha um dos scripts:
- `~/.claude/statusline.sh` — padrão
- `~/.claude/statusline-compact.sh` — compacto com emoji

### Opção B: via NixOS Module
(Futura integração em `/workspace/modules/`)

---

## Símbolos e Significados

| Símbolo | Significado |
|---------|------------|
| `🔌` | Session/Conexão |
| `🧠` | Modelo LLM |
| `📊` | Context window |
| `💾` | (Futuro) Créditos |
| `W:n` | Workers ativos |
| `R:n` | Tasks em andamento (Running) |

---

## Formato do JSON

**statusLine** em `settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "<caminho-para-script.sh>"
  }
}
```

O script recebe como stdin um JSON com:
```json
{
  "model": {
    "display_name": "Opus 4.6..."
  },
  "context_window": {
    "used_percentage": 42.5
  },
  "transcript_path": "/path/to/transcript.jsonl",
  "session": "nova-sessao"
}
```

---

## Customizações

### Mudar shorthand do modelo
Em `statusline-compact.sh`, linha ~48:
```bash
MODEL_SHORT=$(echo "$MODEL" | grep -oE "^[a-zA-Z]+" | tr '[:upper:]' '[:lower:]' | head -c 3)
```

Exemplos de output:
- "Opus 4.6" → "opi"
- "Claude Haiku" → "cla" (primeiro 3 chars do "Claude")
- "Sonnet" → "son"

### Adicionar créditos (💾)
Futuro: integrar com API de créditos do Claude Code (quando disponível).

### Trocar emojis
Edite as linhas com emoji símbolos em `statusline-compact.sh`.

---

## Troubleshooting

### Status line não aparece
1. Confirme que o script é executável: `chmod +x ~/.claude/statusline.sh`
2. Teste manualmente:
   ```bash
   echo '{"model": {"display_name": "Test"}, "context_window": {"used_percentage": 50}}' | bash ~/.claude/statusline.sh
   ```

### Encoding de emojis quebrado
Certifique-se que o terminal suporta UTF-8:
```bash
echo $LANG
# deve ser algo como: en_US.UTF-8
```

---

## Referência Histórica

- **2026-03-14**: Criação de `statusline-compact.sh` com suporte a emojis
- **Anterior**: Statusline padrão (`statusline.sh`) com formato texto
