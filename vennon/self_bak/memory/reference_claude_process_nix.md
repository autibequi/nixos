---
name: reference_claude_process_nix
description: Nome real do processo Claude Code no nix store — .claude-unwrapped, não /bin/claude
type: reference
---

Quando Claude Code é instalado via nix, o processo se chama `.claude-unwrapped` dentro do nix store path:

```
/nix/store/<hash>-claude-code-<version>/bin/.claude-unwrapped --model ... --name projects
```

**Para contar sessões ativas** via `docker top`:
- Filtrar por `.claude-unwrapped` (não `/bin/claude`)
- Filtrar também por `pts/` no campo TTY para pegar só sessões com terminal ativo
- Linhas com `?` no TTY são subprocessos filhos — ignorar para contagem de agentes

**Exemplo correto:**
```rust
.filter(|line| line.contains(".claude-unwrapped") && line.contains("pts/"))
```

**How to apply:** Qualquer código que precise detectar processos Claude rodando em containers nix deve usar esse filtro.
