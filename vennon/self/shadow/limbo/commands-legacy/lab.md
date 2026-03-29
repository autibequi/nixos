# /meta:lab — Modo Laboratório

Ativa o diálogo de laboratório entre Claude externo (eu, falando com o user) e Claude interno (instância análise spawned por mim).

## Arquitetura do Lab

```
User ──► Claude EXTERNO (eu, esta sessão)
              │
              ├── /workspace/self/      ← meu source code
              ├── /workspace/home/       ← nixos repo (mesma coisa, editável)
              ├── /workspace/obsidian/  ← cérebro persistente
              │
              └── spawn ──► Claude INTERNO (analysis mode, haiku)
                                │
                                ├── vê: vennon_ANALYSIS_MODE=1
                                ├── pode: rodar bash, ler/editar arquivos
                                ├── NÃO tem: Docker socket (GID 131 ausente)
                                └── output: volta pra mim via tee/logfile
```

**Importante**: modificar o Claude interno NÃO modifica meu código.
O interno é efêmero — apenas eu (externo) persistir mudanças em `/workspace/home/self/`.

## Como invocar o Claude interno

```bash
vennon_ANALYSIS_MODE=1 HEADLESS=1 IN_DOCKER=1 CLAUDE_ENV=container \

HEADLESS=1 vennon_ANALYSIS_MODE=1 IN_DOCKER=1 CLAUDE_ENV=container \
  timeout 600 claude \
  --permission-mode bypassPermissions \
  --model claude-haiku-4-5-20251001 \
  --max-turns 10 \
  --add-dir /workspace/home \
  -p "SEU_PROMPT_AQUI" 2>&1

```

**Pitfall**: `-p` não aceita string começando com `---`. Sempre usar `--append-system-prompt-file` para o boot context e `-p` para a instrução específica.

## Mapa do ambiente (sempre válido nesta sessão)

| Path | O que é | Editável? |
|------|---------|-----------|
| `/workspace/self/` | source vennon (symlink de `/workspace/home/self/`) | sim via mnt |
| `/workspace/home/` | nixos repo do host montado rw | sim |
| `/workspace/home/self/` | **fonte da verdade** — hooks, skills, agents, scripts | sim |
| `/workspace/obsidian/` | vault Obsidian, persistente entre sessões | sim |
| `/workspace/obsidian/tasks/` | kanban TODO/DOING/DONE | sim |
| `/workspace/obsidian/vault/agents/` | memória e outputs dos agentes | sim |
| `/workspace/obsidian/vault/.ephemeral/cron-logs/` | logs de execução por agente | leitura |
| `/home/claude/.claude/` | config Claude Code (memórias, hooks, skills montados) | sim |
| `/home/claude/.nix-profile/bin/claude` | Claude CLI v2.1.79 | — |
| `/tmp/vennon-locks/` | locks de tasks (atomic mkdir) | runtime |
| `/var/run/docker.sock` | Docker socket — GID 131, eu tenho GID 1000+190 | **sem acesso** |

## Limitações desta sessão (--host sem restart)

- **Sem Docker**: socket precisa GID 131, não estou no grupo
- `yaa tasks run X` requer Docker → precisa rodar no host
- `vennon --host` do host spawna container com `group_add: [131]` — ao reiniciar terei acesso
- O que posso fazer: Claude interno direto, editar arquivos, rodar scripts, task-runner.sh

## Workflow lab

1. **Identificar hipótese**: algo no sistema que quer testar/melhorar
2. **Spawn interno**: invocar haiku com contexto específico e tarefa delimitada
3. **Observar output**: o interno age, eu leio resultado
4. **Aplicar se válido**: eu (externo) edito `/workspace/home/self/` com o que o interno descobriu
5. **Iterar**: re-spawn com hipótese refinada

## Exemplos de uso

```bash
# Testar se o runner captura erros corretamente
# → spawn interno com card quebrado proposital

# Inspecionar comportamento do scheduler
# → spawn interno: "lê scheduler.md e diz o que vai fazer"

# Debug de hook
# → spawn interno com vennon_DEBUG=ON e ver o que injeta

# Teste de cota
# → spawn interno com usage artificialmente alto e ver se bloqueia
```

## Ao ativar /meta:lab

Eu devo:
1. Confirmar que entendi a arquitetura atual
2. Reportar estado atual: tasks pendentes, DOING orphans, última execução
3. Propor o que testaria no lab agora
4. Aguardar direção do user ou agir se tiver permissão clara

---

## Instalar Módulo — workflow de persistência

**Regra fundamental:**
- O mini-Claude cria/modifica em filesystem compartilhado → **persiste** (host mounts)
- O que realmente morre: o **contexto da conversa** (RAM) — não o filesystem
- Memórias (`~/.claude/`) → no host, persistem entre sessões
- Source code (`~/nixos/self/`) → no host, git push para compartilhar/backup
- Único caminho pra persistir: `editar /workspace/home/self/` → `git commit` → `git push`

### Quando o user diz "instala o módulo"

Significa: pegar o que foi criado/descoberto no mini-Claude e aplicar em mim mesmo.

Workflow:
```
mini-Claude cria/modifica algo
       ↓
user: "instala o módulo"
       ↓
eu (externo) leio o que o mini fez
       ↓
aplico em /workspace/home/self/ (hooks, skills, scripts, agents, etc.)
       ↓
commit + push = permanente
```

### Onde cada coisa persiste

| O que | Onde salvar | Como persiste |
|-------|-------------|---------------|
| Hooks, skills, scripts | `/workspace/home/self/` | git commit + push |
| Memórias cross-session | `/home/claude/.claude/projects/*/memory/` | volume Docker (some se volume deletado) |
| Tasks/kanban | `/workspace/obsidian/tasks/` | vault Obsidian do user |
| Memória dos agentes | `/workspace/obsidian/vault/agents/` | vault Obsidian do user |
| Tudo que o mini cria | filesystem compartilhado (host mounts) | persiste entre restarts |

### Pós-instalação

Depois de instalar um módulo, sempre:
1. `bash -n <arquivo>` — syntax check
2. Testar localmente se possível
3. `git commit` com mensagem descritiva
4. Checar se precisa de `yaa update` no host (mudanças no CLI bashly)

---

## Mini-vennon — a maquete

**Mini-vennon** é o nome da versão maquete — o Claude interno (haiku) que eu spawno para desenvolver antes de instalar o módulo em mim mesmo.

```
Mini-vennon (haiku, efêmero)     →    vennon (sonnet, eu, persistente via git)
  experimenta                         recebe o módulo instalado
  prototipa                           commita
  quebra à vontade                    é o produto final
  morre no restart
```

### Por que usar Mini-vennon antes de instalar

- Testar hipóteses sem risco de quebrar meu próprio funcionamento
- Iterar rápido (haiku é barato e rápido)
- O mini pode errar, tentar de novo, explorar caminhos ruins
- Só o que funciona chega em mim

### Ciclo completo

```
1. user identifica algo a melhorar em mim
2. eu spawno Mini-vennon com a hipótese
3. Mini-vennon desenvolve/testa no filesystem compartilhado
4. eu leio o resultado
5. user: "instala o módulo"
6. eu aplico em /workspace/home/self/ + commit + push
7. Mini-vennon some — o módulo vive em mim
```

### Nomenclatura

| Nome | O que é |
|------|---------|
| **vennon** | eu — Claude externo, sonnet, esta sessão |
| **Mini-vennon** | Claude interno — haiku, efêmero, spawned por mim |
| **Instalar módulo** | extrair do Mini-vennon e aplicar em mim via git |
| **Lab** | o ambiente onde essa iteração acontece |
