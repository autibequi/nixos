---
name: feedback_leech_scripts_source
description: Fonte da verdade para scripts do container Puppy/Leech é leech/scripts/, não scripts/
type: feedback
---

Para scripts que rodam via systemd/tick (task-runner.sh, task-daemon.sh): **sempre editar `leech/scripts/`**.

**Why:** O container monta `leech/` em `/workspace/self`. Os arquivos em `scripts/` (raiz do repo) são apenas symlinks → `../leech/scripts/`. Editar `scripts/` diretamente não afeta o container. Erro cometido: editei scripts em `scripts/` (raiz) — o container continuou usando as versões antigas de `leech/scripts/`.

**How to apply:**
- `leech/scripts/` = fonte da verdade para scripts do container
- `scripts/` = symlinks para `leech/scripts/` (para acesso no host via `leech edit`)
- `scripts/bootstrap.sh` e `leech/scripts/bootstrap.sh` são DIFERENTES intencionalmente (não são symlinks)
- Path no container: `/workspace/self/scripts/<arquivo>.sh`
- Ao criar novo script de container: criar em `leech/scripts/`, depois fazer symlink em `scripts/`
