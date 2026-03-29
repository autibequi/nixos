---
name: self:envs
description: "Lista todas as variáveis de ~/.vennon — tokens mascarados com ruído aleatório, flags e semáforos visíveis."
---

# /self:envs — Variáveis de Ambiente Centralizadas

Exibe o conteúdo de `~/.vennon` organizado por seção.
Valores sensíveis (tokens, keys, senhas) são mascarados com ruído aleatório gerado na hora.

```
/self:envs          → lista completa com mascaramento
/self:envs raw      → mostra chaves sem valores (só existência)
/self:envs set KEY=VALUE → define ou atualiza uma variável em ~/.vennon
/self:envs unset KEY     → remove uma variável de ~/.vennon
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
  ...

ENGINE
  engine              claude
  model_claude        sonnet
  ...

BOOT FLAGS
  PERSONALITY         ON
  AUTOCOMMIT          OFF
  ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  arquivo: ~/.vennon    tokens: N/M definidos    flags: N ativas
```

### Subcomando `set`

Se `args = set KEY=VALUE`:
1. Verificar se KEY já existe em `~/.vennon`
   - Se sim: substituir a linha com `sed -i`
   - Se não: append na seção adequada
2. Confirmar: `KEY atualizado em ~/.vennon`

### Subcomando `unset`

Se `args = unset KEY`:
```bash
sed -i "s/^KEY=.*/KEY=/" ~/.vennon
```

---

## Notas

- `~/.vennon` é sourced por TODOS os hooks e pelo entrypoint do container
- Mountado em todos os containers: `~/.vennon` (vennon) e `/.vennon` (app containers)
- Alterações tomam efeito no próximo boot da sessão
- Para efeito imediato no processo atual: `source ~/.vennon`
