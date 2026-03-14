# OpenCode Configuration

Gerenciamento de configuração opencode via stow.

## Estrutura

- `package.json` — Dependências incluindo `opencode-lmstudio@latest`
- `.gitignore` — Ignora node_modules, lockfile, databases
- `node_modules/` — Dependências instaladas (via stow → `~/.config/opencode/`)

## Setup

### Automático (container)

```bash
bash /workspace/stow/.claude/scripts/setup-opencode.sh
```

### Manual (host)

```bash
# No host (fora do container):
cd ~/.config/opencode
bun install

# Teste:
opencode --version
```

## Plugins Instalados

- `opencode-lmstudio@latest` — LM Studio integration for opencode

## Notas

- Config é sincronizada via stow: `stow/.config/opencode/` → `~/.config/opencode/`
- Dependências precisam de `bun` (não disponível no container)
- Se estiver em container, rode `bun install` no host
