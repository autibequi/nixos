cat << 'EOF'

    ┌─ ENGINE SHORTCUTS ────────────────────────────────────────────┐
    │                                                                │
    │  zion claude [dir]       nova sessao com Claude                │
    │  zion cursor [dir]       nova sessao com Cursor                │
    │  zion opencode [dir]     nova sessao com OpenCode (alias: oc)  │
    │  zion ask [prompt]       envia prompt ao Puppy (alias query)   │
    │                                                                │
    ├─ SESSIONS (--haiku / --opus / --sonnet em todos) ───────────────┤
    │                                                                │
    │  zion                    continua ultima sessao                │
    │  zion new --engine=<e>   nova sessao interativa                │
    │  zion resume             lista e retoma sessao                 │
    │  zion lab                edita repo NixOS + logs (lab_mode)    │
    │  zion shell              bash no container                     │
    │                                                                │
    ├─ CONTRACTORS (agentes background) ────────────────────────────┤
    │                                                                │
    │  zion contractors run <nome>   roda contractor agora          │
    │  zion contractors run <n> -s N sobrescreve steps              │
    │  /contractor:call              conversa interativa             │
    │                                                                │
    ├─ INBOX / OUTBOX ──────────────────────────────────────────────┤
    │                                                                │
    │  zion inbox               mostra inbox.md completo            │
    │  zion inbox "mensagem"    adiciona entrada ao inbox            │
    │  zion outbox              lista arquivos do outbox             │
    │                                                                │
    ├─ RUNNER (servicos estrategia) ────────────────────────────────┤
    │                                                                │
    │  zion runner monolito start/stop/logs/shell/build/install      │
    │  zion runner monolito-worker start/stop/logs/shell             │
    │  zion runner bo-container start/stop/logs/shell                │
    │  zion runner front-student start/stop/logs/shell               │
    │                                                                │
    │  Aliases: mono, mw, bo, front | Flags: --env --debug           │
    │  Alias: zion dk                                                │
    │                                                                │
    ├─ CONTAINER ───────────────────────────────────────────────────┤
    │                                                                │
    │  zion build              build da imagem docker                │
    │  zion down               para todos os containers              │
    │  zion clean              remove sessoes paradas (gc, prune)    │
    │                                                                │
    ├─ META ─────────────────────────────────────────────────────────┤
    │                                                                │
    │  zion status             status agregado (sessoes/runner)      │
    │                                                                │
    ├─ INTERNO (systemd) ──────────────────────────────────────────┤
    │                                                                │
    │  zion tasks tick     executa contractors vencidos (scheduler) │
    │  (timer: zion-tick.timer a cada 10min — não chamar direto)     │
    │                                                                │
    ├─ UTIL ─────────────────────────────────────────────────────────┤
    │                                                                │
    │  zion update             regenera CLI + symlink                │
    │  zion init               cria ~/.zion config                   │
    │  zion help               banner                                │
    │  zion man                esta pagina                           │
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
    │  zion claude  = zion new --engine=claude                       │
    │  zion cursor  = zion new --engine=cursor                       │
    │  zion oc      = zion new --engine=opencode                     │
    │  zion dk      = zion runner                                    │
    │  zion ct      = zion contractors                               │
    │  zion st      = zion status                                    │
    │                                                                │
    └────────────────────────────────────────────────────────────────┘
EOF
