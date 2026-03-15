# Sandbox

Espaço de trabalho efêmero para testes e experimentos.

---

### Comandos úteis

```bash
# Criar ambiente nix
nix-shell -p python310

# Build rápido
nix-build

# Eval módulo
nix eval --raw nixosConfigurations.claude.config.system.build.toplevel
```
