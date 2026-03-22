---
name: meta:envs
description: "Lista todas as variáveis de ~/.leech — tokens mascarados com ruído aleatório, flags e semáforos visíveis."
---

# /meta:envs — Variáveis de Ambiente Centralizadas

Exibe o conteúdo de `~/.leech` organizado por seção.
Valores sensíveis (tokens, keys, senhas) são mascarados com ruído aleatório gerado na hora.

```
/meta:envs          → lista completa com mascaramento
/meta:envs raw      → mostra chaves sem valores (só existência)
/meta:envs set KEY=VALUE → define ou atualiza uma variável em ~/.leech
/meta:envs unset KEY     → remove uma variável de ~/.leech
```

---

## Execução

### 1. Ler e parsear ~/.leech

```bash
cat ~/.leech 2>/dev/null || cat /.leech 2>/dev/null || echo "(arquivo não encontrado)"
```

### 2. Gerar tabela mascarada

Para cada variável encontrada (ignorar linhas `#` e em branco):

**Chaves sensíveis** (mascarar valor com ruído aleatório):
```
ANTHROPIC_API_KEY  GH_TOKEN  CURSOR_API_KEY  GRAFANA_TOKEN
CLAUDE_SESSION     DANGER    _KEY  _TOKEN  _SECRET  _PASSWORD  _PAT
```

**Regra de mascaramento:**
- Se vazio → `(vazio)`
- Se preenchido → gerar máscara: primeiros 4 chars reais + `[RANDOM_8]` + `...` onde RANDOM_8 é gerado com:
  ```bash
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8
  ```
  Exemplo: `sk-a[xK9mPqRt]...` ou `ghp_[bN3jWvZm]...`

**Chaves não-sensíveis** (mostrar valor real):
```
engine  model_*  PERSONALITY  AUTOCOMMIT  AUTOJARVIS  BETA
LEECH_DEBUG  HEADLESS  LEECH_ANALYSIS_MODE  MESSAGE  TASK_LOCK
ACTIVE_AGENT  NOTE  OBSIDIAN_PATH  CLAUDIO_NIXOS_DIR  GRAFANA_URL
```

### 3. Formato de saída

Imprimir no terminal em ASCII com seções:

```
~/.leech — Variáveis de Ambiente Centralizadas
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TOKENS
  ANTHROPIC_API_KEY   sk-a[xK9mPqRt]...        [definido]
  GH_TOKEN            ghp_[bN3jWvZm]...         [definido]
  CURSOR_API_KEY                                 (vazio)
  CLAUDE_SESSION                                 (vazio)
  GRAFANA_URL         https://grafana.pla...     [visível]
  GRAFANA_TOKEN       glsa[Qm7nXzKv]...         [definido]

ENGINE
  engine              claude
  model_claude        sonnet
  model_cursor        auto

PATHS
  OBSIDIAN_PATH       /home/pedrinho/.ovault/Work
  CLAUDIO_NIXOS_DIR   /home/pedrinho/nixos

BOOT FLAGS
  PERSONALITY         ON
  AUTOCOMMIT          OFF
  AUTOJARVIS          OFF
  BETA                OFF
  LEECH_DEBUG          OFF
  HEADLESS            0
  LEECH_ANALYSIS_MODE  0

SEMÁFOROS / COMUNICAÇÃO
  MESSAGE                                        (vazio)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  arquivo: ~/.leech    tokens: 3/6 definidos    flags: 7 ativas
```

### Subcomando `set`

Se `args = set KEY=VALUE`:
1. Verificar se KEY já existe em `~/.leech`
   - Se sim: substituir a linha com `sed -i`
   - Se não: append na seção adequada (inferir pela categoria do KEY)
2. Confirmar: `KEY atualizado em ~/.leech`

```bash
# Exemplo: atualizar PERSONALITY
sed -i "s/^PERSONALITY=.*/PERSONALITY=OFF/" ~/.leech
```

### Subcomando `unset`

Se `args = unset KEY`:
```bash
sed -i "s/^KEY=.*/KEY=/" ~/.leech   # limpa valor mas mantém a linha
```

---

## Notas

- `~/.leech` é sourced por TODOS os hooks e pelo entrypoint do container
- Mountado em todos os containers: `~/.leech` (leech) e `/.leech` (app containers)
- Alterações tomam efeito no próximo boot da sessão
- Para efeito imediato no processo atual: `source ~/.leech`
