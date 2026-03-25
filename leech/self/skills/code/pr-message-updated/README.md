# code/pr-message — cópia atualizada (JIRA + template)

O diretório `pr-message/` ao lado é **root:root** neste mount; não foi possível sobrescrever in-place.

**Conteúdo canônico:** `SKILL.md` aqui dentro (idêntico a `/workspace/mnt/.cursor/skills/code/pr-message/SKILL.md`).

**No host**, para instalar no path esperado pelo Leech:

```bash
sudo install -o root -g root -m 644 \
  /workspace/host/leech/self/skills/code/pr-message-updated/SKILL.md \
  /workspace/host/leech/self/skills/code/pr-message/SKILL.md
```

Ou, se preferires mover a pasta inteira:

```bash
sudo rm -rf /workspace/host/leech/self/skills/code/pr-message
sudo mv /workspace/host/leech/self/skills/code/pr-message-updated /workspace/host/leech/self/skills/code/pr-message
```

**Cópia extra** (mesmo arquivo): `../pr-message.SKILL.md` no diretório pai `code/`.
