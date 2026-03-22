---
name: reference_zion_git_commit
description: Como commitar mudanças em /workspace/self/ — git repo fica em /workspace/host/ mas é read-only no container
type: reference
---

O repo git do Zion (`self/`) está em `/workspace/host/.git` com work tree `/workspace/host/`.

No container, `/workspace/host/` é **read-only** — não é possível fazer `git commit` de dentro do container.

**Para commitar mudanças em `/workspace/self/`:**
- Pedir ao usuário para commitar no host (`cd ~/nixos && git add ... && git commit`)
- Ou usar o comando `zion commit` se disponível no host

**How to apply:** Após editar arquivos em `/workspace/self/`, avisar o usuário que o commit precisa ser feito no host — não tentar `git -C /workspace/host` dentro do container.
