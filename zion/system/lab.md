# /meta:lab — Modo Laboratório

Ativa o diálogo de laboratório entre Claude externo (eu, falando com o user) e Claude interno (instância análise spawned por mim).

## Arquitetura do Lab

```
User ──► Claude EXTERNO (eu, esta sessão)
              │
              ├── /workspace/zion/      ← meu source code
              ├── /workspace/mnt/       ← nixos repo (mesma coisa, editável)
              ├── /workspace/obsidian/  ← cérebro persistente
              │
              └── spawn ──► Claude INTERNO (analysis mode, haiku)
                                │
                                ├── vê: ZION_ANALYSIS_MODE=1
                                ├── pode: rodar bash, ler/editar arquivos
                                ├── NÃO tem: Docker socket (GID 131 ausente)
                                └── output: volta pra mim via tee/logfile
```

**Importante**: modificar o Claude interno NÃO modifica meu código.
O interno é efêmero — apenas eu (externo) persistir mudanças em `/workspace/mnt/zion/`.

## Como invocar o Claude interno

```bash
SYSFILE=$(mktemp /tmp/lab-sys-XXXX.md)
ZION_ANALYSIS_MODE=1 HEADLESS=1 IN_DOCKER=1 CLAUDE_ENV=container \
  /workspace/mnt/zion/hooks/claude-code/session-start.sh 2>/dev/null > "$SYSFILE"

HEADLESS=1 timeout 120 claude \
  --permission-mode bypassPermissions \
  --model claude-haiku-4-5-20251001 \
  --max-turns 10 \
  --append-system-prompt-file "$SYSFILE" \
  -p "SEU_PROMPT_AQUI" 2>&1

rm -f "$SYSFILE"
```

**Pitfall**: `-p` não aceita string começando com `---`. Sempre usar `--append-system-prompt-file` para o boot context e `-p` para a instrução específica.

## Mapa do ambiente (sempre válido nesta sessão)

| Path | O que é | Editável? |
|------|---------|-----------|
| `/workspace/zion/` | source zion (symlink de `/workspace/mnt/zion/`) | sim via mnt |
| `/workspace/mnt/` | nixos repo do host montado rw | sim |
| `/workspace/mnt/zion/` | **fonte da verdade** — hooks, skills, agents, scripts | sim |
| `/workspace/obsidian/` | vault Obsidian, persistente entre sessões | sim |
| `/workspace/obsidian/tasks/` | kanban TODO/DOING/DONE | sim |
| `/workspace/obsidian/agents/memory/` | memória dos agentes | sim |
| `/workspace/obsidian/agents/cron/runs/` | logs de execução por agente | leitura |
| `/home/claude/.claude/` | config Claude Code (memórias, hooks, skills montados) | sim |
| `/home/claude/.nix-profile/bin/claude` | Claude CLI v2.1.79 | — |
| `/tmp/zion-locks/` | locks de tasks (atomic mkdir) | runtime |
| `/var/run/docker.sock` | Docker socket — GID 131, eu tenho GID 1000+190 | **sem acesso** |

## Limitações desta sessão (zion edit sem restart)

- **Sem Docker**: socket precisa GID 131, não estou no grupo
- `zion tasks run X` requer Docker → precisa rodar no host
- `zion edit` do host spawna container com `group_add: [131]` — ao reiniciar terei acesso
- O que posso fazer: Claude interno direto, editar arquivos, rodar scripts, task-runner.sh

## Workflow lab

1. **Identificar hipótese**: algo no sistema que quer testar/melhorar
2. **Spawn interno**: invocar haiku com contexto específico e tarefa delimitada
3. **Observar output**: o interno age, eu leio resultado
4. **Aplicar se válido**: eu (externo) edito `/workspace/mnt/zion/` com o que o interno descobriu
5. **Iterar**: re-spawn com hipótese refinada

## Exemplos de uso

```bash
# Testar se o runner captura erros corretamente
# → spawn interno com card quebrado proposital

# Inspecionar comportamento do scheduler
# → spawn interno: "lê scheduler.md e diz o que vai fazer"

# Debug de hook
# → spawn interno com ZION_DEBUG=ON e ver o que injeta

# Teste de cota
# → spawn interno com usage artificialmente alto e ver se bloqueia
```

## Ao ativar /meta:lab

Eu devo:
1. Confirmar que entendi a arquitetura atual
2. Reportar estado atual: tasks pendentes, DOING orphans, última execução
3. Propor o que testaria no lab agora
4. Aguardar direção do user ou agir se tiver permissão clara
