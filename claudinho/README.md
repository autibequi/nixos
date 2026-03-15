# ClaudeOS — movido

Lógica do ambiente do container foi movida para:

- **`../modules/agents/agent-container/`**
  - `packages.nix` — lista de pacotes do container
  - `flake.nix` — flake para build do env (ex.: `nix build ./modules/agents/agent-container#default` na raiz do repo)
