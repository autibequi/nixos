# Renomear para zion

O refactor Claudinho/Claudio → Zion está feito. Falta apenas renomear a pasta no host:

```bash
cd /nixos  # ou onde está o repo (ex.: ~/nixos)
mv claudinho zion  # já feito
```

Depois: `make install` (a partir de `/nixos/zion`) ou `zion update` para regenerar o CLI e instalar o symlink `~/.local/bin/zion`.

Alias retrocompatível no `~/.zshrc`: `alias claudio=zion`
