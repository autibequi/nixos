---
name: reference_container_host_paths
description: Env vars que expõem os paths reais do host dentro do container Leech
type: reference
---

Dentro do container, estas env vars contêm os paths absolutos do HOST:

| Env var | Path no container | Path no host (exemplo) |
|---------|-------------------|------------------------|
| `CLAUDIO_MOUNT` | `/workspace/mnt/` | `/home/pedrinho/projects/monolito` |
| `LEECH_ROOT` | `/workspace/self/` | `/home/pedrinho/nixos/leech/self` |
| `OBSIDIAN_PATH` | `/workspace/obsidian/` | `/home/pedrinho/.ovault/Work` |

`LEECH_ROOT` é a referência mais confiável — setado pelo CLI antes do `docker compose up`, chega como env var absoluta. Exposto no BOOT como `host_self=$LEECH_ROOT`.

`OBSIDIAN_PATH` vem do `~/.leech` — $HOME dentro do container é `/home/claude`, não o home do host. Pode expandir diferente.

Usar `host_self` para navegar até a estrutura real do leech/nixos no host (cursor links, referências de path).
