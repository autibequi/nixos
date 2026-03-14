# OpenClaw config (LM Studio no host)

Template em `openclaw.json` usa **host.docker.internal:1234** para o container alcançar o LM Studio rodando no host.

- **Primeira vez:** `make openclaw` copia este `openclaw.json` para `~/.openclaw/` no host.
- Ajuste o `id` do modelo em `~/.openclaw/openclaw.json` para o nome que o LM Studio expõe em `http://127.0.0.1:1234/v1/models` (ex.: `minimax-m2.1-gs32`, `llama-3.1-8b`, etc.).
- Suba o LM Studio e ative o servidor local (porta 1234) antes de `make openclaw`.
