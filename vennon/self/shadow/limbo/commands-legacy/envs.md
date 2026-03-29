---
name: meta:envs
description: "Lista todas as variáveis de ~/.vennon — tokens mascarados com ruído aleatório, flags e semáforos visíveis."
---

# /meta:envs — Variáveis de Ambiente Centralizadas

Exibe o conteúdo de `~/.vennon` organizado por seção.
Valores sensíveis (tokens, keys, senhas) são mascarados com ruído aleatório gerado na hora.

```
/meta:envs          → lista completa com mascaramento
/meta:envs raw      → mostra chaves sem valores (só existência)
/meta:envs set KEY=VALUE → define ou atualiza uma variável em ~/.vennon
/meta:envs unset KEY     → remove uma variável de ~/.vennon
```

---

## Execução

### 1. Ler e parsear ~/.vennon

```bash
cat ~/.vennon 2>/dev/null || cat /.vennon 2>/dev/null || echo "(arquivo não encontrado)"
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
vennon_DEBUG  HEADLESS  vennon_ANALYSIS_MODE  MESSAGE  TASK_LOCK
ACTIVE_AGENT  NOTE  OBSIDIAN_PATH  CLAUDIO_NIXOS_DIR  GRAFANA_URL
```

### 3. Formato de saída

Imprimir no terminal em ASCII com seções:

```
~/.vennon — Variáveis de Ambiente Centralizadas
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
  vennon_DEBUG          OFF
  HEADLESS            0
  vennon_ANALYSIS_MODE  0

SEMÁFOROS / COMUNICAÇÃO
  MESSAGE                                        (vazio)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  arquivo: ~/.vennon    tokens: 3/6 definidos    flags: 7 ativas
```

### Subcomando `set`

Se `args = set KEY=VALUE`:
1. Verificar se KEY já existe em `~/.vennon`
   - Se sim: substituir a linha com `sed -i`
   - Se não: append na seção adequada (inferir pela categoria do KEY)
2. Confirmar: `KEY atualizado em ~/.vennon`

```bash
# Exemplo: atualizar PERSONALITY
sed -i "s/^PERSONALITY=.*/PERSONALITY=OFF/" ~/.vennon
```

### Subcomando `unset`

Se `args = unset KEY`:
```bash
sed -i "s/^KEY=.*/KEY=/" ~/.vennon   # limpa valor mas mantém a linha
```

---

## Notas

- `~/.vennon` é sourced por TODOS os hooks e pelo entrypoint do container
- Mountado em todos os containers: `~/.vennon` (vennon) e `/.vennon` (app containers)
- Alterações tomam efeito no próximo boot da sessão
- Para efeito imediato no processo atual: `source ~/.vennon`
