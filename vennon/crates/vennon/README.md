# vennon — Container Management

Gerencia containers via podman-compose. Dois tipos:

## IDE Containers (compose gerado em Rust)

```bash
vennon claude [start|stop|shell|build|flush]
vennon opencode [start|stop|shell|build|flush]
vennon cursor [start|stop|shell|build|flush]
```

- Compose gerado por `containers/ide.rs` com volumes estáveis
- Imagens: `vennon-vennon` (base) → `vennon-claude/opencode/cursor`
- `start`: up -d + exec into container
- `shell`: up -d + exec zsh
- `build`: rebuilda base + child
- Auto-build se imagem não existe

## Service Containers (compose estático + vennon.yaml)

```bash
vennon monolito serve --env=sand
vennon mono stop
vennon front serve --env=local --vertical=medicina
vennon proxy serve
vennon list
```

- Manifest em `vennon.yaml` define commands, enums, compose files
- Template rendering: `{{ env | map }}` (sand → sandbox)
- Conditional compose files: `if: debug` → `docker-compose.debug.yml`
- `VENNON_SERVICE_DIR` env var injetada para Dockerfile paths

## Módulos

| Arquivo | O que faz |
|---------|-----------|
| `main.rs` | CLI (init, update, list, external_subcommand) |
| `config.rs` | Paths, config loading, git_env(), user_ids() |
| `manifest.rs` | vennon.yaml parser, discovery, template engine |
| `container.rs` | IDE dispatch (start/stop/shell/build/flush) |
| `service.rs` | Service dispatch (compose/exec/script) |
| `compose.rs` | YAML structs + write-if-changed |
| `exec.rs` | Process helpers (run/capture/exec_replace) |
| `containers/mod.rs` | IDE engine list, start_cmd(), container_workdir() |
| `containers/ide.rs` | Compose generation (volumes, env, docker-proxy) |
