cat << 'EOF'

    ┌─ ENGINE SHORTCUTS ────────────────────────────────────────────┐
    │                                                                │
    │  leech claude [dir]       nova sessao com Claude                │
    │  leech cursor [dir]       nova sessao com Cursor                │
    │  leech opencode [dir]     nova sessao com OpenCode (alias: oc)  │
    │  leech ask [prompt]       envia prompt ao Puppy (alias query)   │
    │                                                                │
    ├─ SESSIONS (--haiku / --opus / --sonnet em todos) ───────────────┤
    │                                                                │
    │  leech                    continua ultima sessao                │
    │  leech new --engine=<e>   nova sessao interativa                │
    │  leech resume             lista e retoma sessao                 │
    │  leech host [dir]          sessao + /workspace/host editavel      │
    │  leech shell              bash no container                     │
    │                                                                │
    ├─ CONTRACTORS (agentes background) ────────────────────────────┤
    │                                                                │
    │  leech contractors run <nome>   roda contractor agora          │
    │  leech contractors run <n> -s N sobrescreve steps              │
    │  /contractor:call              conversa interativa             │
    │                                                                │
    ├─ INBOX / OUTBOX ──────────────────────────────────────────────┤
    │                                                                │
    │  leech inbox               mostra inbox.md completo            │
    │  leech inbox "mensagem"    adiciona entrada ao inbox            │
    │  leech outbox              lista arquivos do outbox             │
    │                                                                │
    ├─ RUNNER (servicos estrategia) ────────────────────────────────┤
    │                                                                │
    │  leech runner monolito start/stop/logs/shell/build/install      │
    │  leech runner monolito-worker start/stop/logs/shell             │
    │  leech runner bo-container start/stop/logs/shell                │
    │  leech runner front-student start/stop/logs/shell               │
    │                                                                │
    │  Aliases: mono, mw, bo, front | Flags: --env --debug           │
    │  Alias: leech dk                                                │
    │                                                                │
    ├─ CONTAINER ───────────────────────────────────────────────────┤
    │                                                                │
    │  leech build              build da imagem docker                │
    │  leech down               para todos os containers              │
    │  leech clean              remove sessoes paradas (gc, prune)    │
    │                                                                │
    ├─ META ─────────────────────────────────────────────────────────┤
    │                                                                │
    │  leech status             status agregado (sessoes/runner)      │
    │                                                                │
    ├─ INTERNO (systemd) ──────────────────────────────────────────┤
    │                                                                │
    │  leech tasks tick     executa contractors vencidos (scheduler) │
    │  (timer: leech-tick.timer a cada 10min — não chamar direto)     │
    │                                                                │
    ├─ UTIL ─────────────────────────────────────────────────────────┤
    │                                                                │
    │  leech update             regenera CLI + symlink                │
    │  leech init               cria ~/.leech config                   │
    │  leech help               banner                                │
    │  leech man                esta pagina                           │
    │                                                                │
    ├─ FLAGS GLOBAIS ────────────────────────────────────────────────┤
    │                                                                │
    │  --engine=opencode|claude|cursor                               │
    │  --model=haiku|sonnet|opus  (ou --haiku / --opus / --sonnet)   │
    │  --instance=N            sufixo da instancia                   │
    │  --rw / --ro             modo de mount                         │
    │  --danger                bypass de permissoes                  │
    │  --init-md=FILE          markdown inicial (default contexto.md)│
    │  --resume=UUID           retomar sessao especifica             │
    │                                                                │
    ├─ ALIASES ──────────────────────────────────────────────────────┤
    │                                                                │
    │  leech claude  = leech new --engine=claude                       │
    │  leech cursor  = leech new --engine=cursor                       │
    │  leech oc      = leech new --engine=opencode                     │
    │  leech dk      = leech runner                                    │
    │  leech ct      = leech contractors                               │
    │  leech st      = leech status                                    │
    │                                                                │
    └────────────────────────────────────────────────────────────────┘
EOF
