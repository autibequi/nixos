---
name: nixos-add-pkg
description: Adiciona um pacote ao NixOS — busca no MCP, escolhe o módulo correto, edita e valida com nh os test
category: nixos
tags: #nixos #pacotes #módulos
---

# nixos-add-pkg

Adiciona um pacote ao sistema ou ao usuário (Home Manager) no repositório NixOS. O agente **Nixkeeper** usa este fluxo por padrão.

## Uso

O usuário pede para "instalar X" ou "adicionar pacote X". O agente:

1. Busca o pacote (MCP-NixOS ou `nh search`)
2. Escolhe o módulo conforme a tabela abaixo
3. Edita o arquivo (mantendo estilo existente)
4. Roda `nh os test .`
5. Reporta onde foi adicionado

## Onde adicionar

| Tipo de pacote | Módulo |
|----------------|--------|
| CLI / ferramenta de sistema | `modules/core/packages.nix` |
| App gráfico / desktop | `modules/gnome/packages.nix` (ou DE correspondente) |
| Dev / trabalho | `modules/work.nix` ou `modules/core/packages.nix` |
| Gaming | `modules/steam.nix` |
| Só para o usuário (home) | `modules/core/home.nix` (home.packages) |
| Novo domínio | Criar `modules/<nome>.nix` e import em `configuration.nix` |

## Comandos

```bash
# Buscar (fallback se MCP indisponível)
nh search nixpkgs PACKAGE

# Validar (obrigatório após editar)
nh os test .
```

## Regras

- Sempre buscar antes de adicionar (nome do atributo em nixpkgs).
- Pacotes unstable: usar `unstable.pkgs.PACKAGE` ou `unstable.PACKAGE` (specialArgs).
- Nunca rodar `nh os switch .` a menos que o usuário peça.
