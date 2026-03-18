cat << 'EOF'

    ┌─ PUPPY (workers) ──────────────────────────────────────────────┐
    │                                                                │
    │  zion puppy start          sobe container + daemon             │
    │  zion puppy stop           para o container                    │
    │  zion puppy restart        stop + start                        │
    │  zion puppy run <task>     executa 1 task manual               │
    │  zion puppy tick           roda 1 tick do scheduler            │
    │  zion puppy query [prompt] envia prompt ao Claude              │
    │  zion puppy status         estado do container + tasks         │
    │  zion puppy logs -f        acompanha logs do daemon            │
    │  zion puppy shell          bash dentro do container            │
    │                                                                │
    ├─ DOCKER (servicos estrategia) ────────────────────────────────┤
    │                                                                │
    │  zion docker run <svc>     levanta servico (monolito, etc.)    │
    │  zion docker stop <svc>    para servico + deps                 │
    │  zion docker logs <svc>    mostra/reconecta logs               │
    │  zion docker status        lista containers rodando            │
    │  zion docker shell <svc>   shell no container do servico       │
    │  zion docker restart <svc> restart do servico                  │
    │                                                                │
    │  Flags: --env=sand|qa|prod|local  --detach  --follow  --tail   │
    │  Alias: zion dk                                                │
    │                                                                │
    ├─ SESSIONS ─────────────────────────────────────────────────────┤
    │                                                                │
    │  zion                      continua ultima sessao              │
    │  zion new --engine=claude  nova sessao interativa              │
    │  zion resume               lista e retoma sessao               │
    │  zion edit                 edita repo NixOS + logs             │
    │  zion shell                bash no container                   │
    │  zion start                sobe sandbox + Claude               │
    │                                                                │
    ├─ CONTAINER ───────────────────────────────────────────────────┤
    │                                                                │
    │  zion build                build da imagem docker              │
    │  zion down                 para todos os containers            │
    │  zion destroy              remove containers + volumes         │
    │                                                                │
    ├─ TASKS ────────────────────────────────────────────────────────┤
    │                                                                │
    │  zion new-task <nome>      cria task no kanban                 │
    │                                                                │
    ├─ META ─────────────────────────────────────────────────────────┤
    │                                                                │
    │  zion update               regenera CLI + symlink              │
    │  zion init                 cria ~/.zion config                 │
    │  zion help                 banner                              │
    │  zion man                  esta pagina                         │
    │                                                                │
    ├─ FLAGS GLOBAIS ────────────────────────────────────────────────┤
    │                                                                │
    │  --engine=opencode|claude|cursor                               │
    │  --model=haiku|sonnet|opus                                     │
    │  --instance=N              sufixo da instancia                 │
    │  --rw / --ro               modo de mount                       │
    │  --danger                  bypass de permissoes                │
    │  --resume=UUID             retomar sessao especifica           │
    │                                                                │
    └────────────────────────────────────────────────────────────────┘
EOF
