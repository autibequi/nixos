# Estrutura Zion + Zion CLI

```mermaid
flowchart TB
  subgraph host [Host NixOS]
    User[Usuário]
    CLI["zion (CLI)"]
    Compose[docker compose]
  end

  subgraph cli_src [Zion CLI — fonte]
    Bashly[bashly.yml]
    Commands[commands/*.sh]
    ComposeYml[docker-compose.claude.yml]
  end

  subgraph container [Container claude-nix-sandbox]
    Sandbox[sandbox\nsessão interativa]
    Worker[worker / worker-fast\nPuppy]
    Scheduler[scheduler\nloop 10 min]
  end

  subgraph mounts [Volumes]
    Zion["/zion"]
    Mnt["/workspace/mnt"]
    Obsidian["/workspace/obsidian"]
    Nixos["/workspace/nixos\nsó scheduler + edit"]
  end

  User --> CLI
  CLI --> Bashly
  CLI --> Commands
  CLI --> Compose
  Compose --> ComposeYml
  Compose --> Sandbox
  Compose --> Worker
  Compose --> Scheduler

  Sandbox --> Zion
  Sandbox --> Mnt
  Sandbox --> Obsidian
  Worker --> Zion
  Worker --> Mnt
  Scheduler --> Zion
  Scheduler --> Mnt
  Scheduler --> Nixos
```

---

## Resumo

| Camada | O quê |
|--------|--------|
| **Zion** | Nome do sistema: agentes, container, CLI, bootstrap, skills. Código em `zion/`. |
| **Zion CLI** | Binário `zion` (bashly). Fonte: `zion/cli/src/bashly.yml` + `zion/cli/src/commands/*.sh`. Regenerar com `bashly generate`. |
| **Compose** | `zion/cli/docker-compose.claude.yml` — imagem `claude-nix-sandbox`, serviços sandbox (sessão), worker, scheduler. |
| **sandbox** | Sessão interativa (Cursor/Claude). `network_mode: host`. Volumes base: zion, mnt, obsidian. |
| **worker** | Puppy: `puppy-runner.sh`. Tasks do kanban. |
| **scheduler** | Loop 10 min, `puppy-scheduler.sh`. Único com `/workspace/nixos` montado. |
| **zion edit** | Mesmo sandbox com mnt = repo NixOS e `/workspace/logs` (journal). |
