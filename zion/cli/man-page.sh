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
    ├─ TASKS (kanban TODO/DOING/DONE) ──────────────────────────────┤
    │                                                                │
    │  zion tasks tick          executa cards vencidos (local)       │
    │  zion tasks tick -d       dry-run: lista sem executar          │
    │  zion tasks run <nome>    executa 1 card específico            │
    │  zion tasks run <n> -t N  executa com max-turns override       │
    │  zion tasks list          lista TODO/DOING/DONE                │
    │  zion tasks list -a       inclui DONE                          │
    │  zion tasks new <nome>    cria novo card                       │
    │  zion tasks status        log de execuções                     │
    │  (systemd timer: zion-tick.timer — a cada 10min)               │
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
    │  zion status             status agregado (sessoes/docker)      │
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
    │  zion dk      = zion docker                                    │
    │  zion t       = zion tasks                                     │
    │  zion st      = zion status                                    │
    │  zion wt      = zion worktree                                  │
    │                                                                │
    └────────────────────────────────────────────────────────────────┘
EOF
