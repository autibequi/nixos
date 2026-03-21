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
    │  zion lab                edita repo NixOS + logs (lab_mode)    │
    │  zion shell              bash no container                     │
    │  zion start              [DEPRECATED] use zion claude --danger │
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
    ├─ META ─────────────────────────────────────────────────────────┤
    │                                                                │
    │  zion status             status agregado (sessoes/docker)      │
    │  zion worktree [svc]     lista worktrees interativamente       │
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
    │  zion ct      = zion contractors                               │
    │  zion st      = zion status                                    │
    │  zion wt      = zion worktree                                  │
    │                                                                │
    └────────────────────────────────────────────────────────────────┘
EOF
