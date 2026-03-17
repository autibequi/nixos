---
name: nixos-stow
description: Gestão dos dotfiles com GNU Stow — status, deploy, unstow, listar pacotes em stow/
category: nixos
tags: #nixos #stow #dotfiles
---

# nixos-stow

Gerencia dotfiles no repositório via **GNU Stow**. Os arquivos ficam em `stow/` e são linkados em `~` (ou `~/.config`, etc.). O agente **Nixkeeper** usa este conhecimento para qualquer pedido sobre "stow" ou "dotfiles".

## Contexto

- **Raiz do repo:** `/home/pedrinho/nixos` (ou `~/nixos` no host).
- **Diretório Stow:** `stow/` dentro do repo.
- **Alvo:** `~` (home do usuário). Dentro de `stow/` a estrutura espelha o destino (ex.: `stow/.config/hypr/` → `~/.config/hypr/`).

## Uso

O usuário pede "aplicar stow", "status do stow", "listar pacotes stow", "remover stow de X". O agente:

1. Lista pacotes em `stow/` (diretórios de primeiro nível, ou os que fazem sentido como “pacotes”)
2. Fornece o comando exato para deploy / unstow
3. Para overwrite, sugere dry-run primeiro

## Comandos

### Listar pacotes (o que pode ser stowado)

```bash
# Diretórios em stow/ (cada um = um “pacote” para stow)
ls -d stow/*/ 2>/dev/null || ls stow/
```

Exemplos típicos: `.claude`, `.config`, `ghostty`, `git`, `hyprland`, `waybar`, `zed`.

### Deploy (aplicar stow)

```bash
# De dentro do repo (ex: ~/nixos)
stow -d ~/nixos/stow -t ~ .

# Apenas um pacote
stow -d ~/nixos/stow -t ~ git zed

# Dry-run (ver o que seria linkado, sem alterar)
stow -d ~/nixos/stow -t ~ -n .
```

### Unstow (remover links de um pacote)

```bash
stow -d ~/nixos/stow -t ~ -D git
```

### Status (ver se há conflitos)

- Dry-run mostra se algum arquivo já existe e seria sobrescrito.
- Se houver conflito, Stow avisa; o agente sugere backup ou unstow do pacote conflitante antes.

## Estrutura esperada em stow/

Cada “pacote” é um diretório. Dentro dele, a árvore espelha o destino:

```
stow/git/
  .gitconfig
stow/.config/zed/
  settings.json
```

Com `-t ~`, `stow/git/.gitconfig` → `~/.gitconfig`, e `stow/.config/zed/settings.json` → `~/.config/zed/settings.json`.

## Regras

- Dotfiles são gerenciados por Stow, **não** por módulos NixOS (não colocar conteúdo de stow em `modules/`).
- Sempre usar `-d ~/nixos/stow -t ~` (ou path absoluto do repo) para evitar ambiguidade.
- Em caso de dúvida de overwrite: sugerir `stow -n ...` antes de aplicar.
