---
name: feedback_zion_scripts_source
description: Fonte da verdade para scripts do container Puppy/Zion é zion/scripts/, não scripts/
type: feedback
---

Para scripts que rodam via systemd/tick (task-runner.sh, task-daemon.sh): **sempre editar `zion/scripts/`**.

**Why:** O container monta `zion/` em `/workspace/zion`. Os arquivos em `scripts/` (raiz do repo) são apenas symlinks → `../zion/scripts/`. Editar `scripts/` diretamente não afeta o container. Erro cometido: editei scripts em `scripts/` (raiz) — o container continuou usando as versões antigas de `zion/scripts/`.

**How to apply:**
- `zion/scripts/` = fonte da verdade para scripts do container
- `scripts/` = symlinks para `zion/scripts/` (para acesso no host via `zion edit`)
- `scripts/bootstrap.sh` e `zion/scripts/bootstrap.sh` são DIFERENTES intencionalmente (não são symlinks)
- Path no container: `/workspace/zion/scripts/<arquivo>.sh`
- Ao criar novo script de container: criar em `zion/scripts/`, depois fazer symlink em `scripts/`
