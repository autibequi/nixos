---
name: nixos-remove-pkg
description: Remove um pacote do NixOS — localiza usos, remove do módulo correto e valida com nh os test
category: nixos
tags: #nixos #pacotes #limpeza
---

# nixos-remove-pkg

Remove um pacote da configuração NixOS. O agente **Nixkeeper** segue este fluxo.

## Uso

O usuário pede para "remover X" ou "desinstalar X". O agente:

1. Localiza o pacote no repo (grep em `*.nix` por nome ou atributo)
2. Remove da lista no módulo correto (environment.systemPackages, home.packages, etc.)
3. Verifica se há config associada (programs.X, services.X) e remove ou comenta
4. Roda `nh os test .`
5. Reporta o que foi removido

## Onde procurar

```bash
# Buscar referências ao pacote
grep -r "PACKAGE\|package-name" modules/ --include="*.nix"
```

Possíveis locais:

- `modules/core/packages.nix`
- `modules/gnome/packages.nix`
- `modules/core/home.nix` (home.packages)
- `modules/work.nix`, `modules/steam.nix`, etc.
- `programs.<name>.enable` em `programs.nix` ou `home.nix`
- `services.<name>` em `services.nix`

## Comandos

```bash
# Validar após remoção
nh os test .
```

## Regras

- Remover da lista de pacotes; se houver bloco `programs.X` ou `services.X`, remover ou desabilitar.
- Sempre rodar `nh os test .` após a edição.
- Não rodar `nix-collect-garbage` automaticamente; o usuário pode querer fazer depois.
