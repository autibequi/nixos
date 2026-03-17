---
name: nixos-clean
description: Limpeza do Nix store e gerações — garbage-collect, remover gerações antigas, reportar espaço
category: nixos
tags: #nixos #limpeza #gc #gerações
---

# nixos-clean

Procedimentos para limpar o store Nix e organizar gerações. O agente **Nixkeeper** pode executar ou apenas indicar os comandos (alguns exigem ambiente do usuário).

## Uso

O usuário pede para "limpar", "liberar espaço", "remover gerações antigas". O agente:

1. Explica o que cada comando faz
2. Sugere ordem: primeiro listar/diff, depois GC
3. Opcionalmente roda comandos read-only (listar, diff); comandos destrutivos são sugeridos para o usuário rodar

## Comandos

### Garbage-collect (remover derivações não referenciadas)

```bash
# Seco (só mostra o que seria removido)
nix-store --gc --print-dead

# Coletar lixo (remove não referenciados)
nix-collect-garbage -d
```

### Remover gerações antigas

```bash
# Listar gerações atuais
nix-env --list-generations   # per-user
ls -la /nix/var/nix/profiles/system-*-link  # system

# Deletar gerações do sistema com mais de 7 dias
nix-collect-garbage --delete-older-than 7d
```

### Inspecionar uso

```bash
# Diferença entre duas gerações (o que entrou/saiu)
nix store diff-closures /nix/var/nix/profiles/system-OLDGEN-link /nix/var/nix/profiles/system-NEWGEN-link

# Tamanho do store (aproximado)
du -sh /nix/store
```

## Regras

- `nix-collect-garbage` e `--delete-older-than` alteram o sistema; informar o usuário antes de rodar ou deixar que ele execute.
- Em sandbox (Cursor), comandos que escrevem no /nix/store podem falhar; documentar e sugerir rodar no host.
