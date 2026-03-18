cat << 'EOF'

    ┌─ ENGINE SHORTCUTS ────────────────────────────────────────────┐
    │                                                                │
    │  zion claude [dir]       nova sessao com Claude                │
    │  zion cursor [dir]       nova sessao com Cursor                │
    │  zion opencode [dir]     nova sessao com OpenCode (alias: oc)  │
    │  zion ask [prompt]       envia prompt ao Puppy (alias query)   │
    │                                                                │
    ├─ SESSIONS ─────────────────────────────────────────────────────┤
    │                                                                │
    │  zion                    continua ultima sessao                │
    │  zion new --engine=<e>   nova sessao interativa                │
    │  zion resume             lista e retoma sessao                 │
    │  zion edit               edita repo NixOS + logs               │
    │  zion shell              bash no container                     │
    │  zion start              [DEPRECATED] use zion claude --danger │
    │                                                                │
    ├─ PUPPY (workers) ─────────────────────────────────────────────┤
    │                                                                │
    │  zion puppy start        sobe container + daemon               │
    │  zion puppy stop         para o container                      │
    │  zion puppy restart      stop + start                          │
    │  zion puppy run <task>   executa 1 task manual                 │
    │  zion puppy tick         roda 1 tick do scheduler              │
    │  zion puppy query [p]    envia prompt ao Claude                │
    │  zion puppy status       estado do container + tasks (st)      │
    │  zion puppy logs -f      acompanha logs do daemon              │
    │  zion puppy shell        bash dentro do container              │
    │                                                                │
    ├─ DOCKER (servicos estrategia) ────────────────────────────────┤
    │                                                                │
    │  zion docker run <svc>     levanta servico (monolito, etc.)    │
    │  zion docker stop <svc>    para servico + deps                 │
    │  zion docker logs <svc>    mostra/reconecta logs               │
    │  zion docker status        lista containers rodando            │
    │  zion docker shell <svc>   shell no container do servico       │
    │  zion docker restart <svc> restart do servico                  │
    │  zion docker build <svc>   rebuild da imagem                   │
    │  zion docker install <svc> instala dependencias                │
    │  zion docker flush <svc>   remove tudo do servico              │
    │                                                                │
    │  Flags: --env=sand|qa|prod|local  --detach  --debug            │
    │         --worktree=<name>  --vertical=<v>                      │
    │  Alias: zion dk                                                │
    │                                                                │
    ├─ CONTAINER ───────────────────────────────────────────────────┤
    │                                                                │
    │  zion build              build da imagem docker                │
    │  zion down               para todos os containers              │
    │  zion destroy            remove containers + volumes           │
    │  zion clean              remove sessoes paradas (gc, prune)    │
    │                                                                │
    ├─ TASKS ────────────────────────────────────────────────────────┤
    │                                                                │
    │  zion new-task <nome>    cria task no kanban                   │
    │  zion status             status agregado (sessoes/dk/puppy)    │
    │  zion worktree [svc]     lista worktrees interativamente       │
    │                                                                │
    ├─ META ─────────────────────────────────────────────────────────┤
    │                                                                │
    │  zion update             regenera CLI + symlink                │
    │  zion init               cria ~/.zion config                   │
    │  zion help               banner                                │
    │  zion man                esta pagina                           │
    │                                                                │
    ├─ FLAGS GLOBAIS ────────────────────────────────────────────────┤
    │                                                                │
    │  --engine=opencode|claude|cursor                               │
    │  --model=haiku|sonnet|opus                                     │
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
    │  zion ask     = zion puppy query                               │
    │  zion dk      = zion docker                                    │
    │  zion p       = zion puppy                                     │
    │  zion p st    = zion puppy status                              │
    │  zion st      = zion status                                    │
    │  zion wt      = zion worktree                                  │
    │                                                                │
    └────────────────────────────────────────────────────────────────┘
EOF
