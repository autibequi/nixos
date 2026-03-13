Toggle do Trashman (limpeza automática). Checar se `/workspace/.ephemeral/trashman` existe:

- Se existe: remover o arquivo e confirmar "Trashman DESLIGADO 🗑️"
- Se não existe: criar o arquivo (conteúdo: "on") e confirmar "Trashman LIGADO 🗑️"

Quando LIGADO e invocado para limpeza (não toggle), executar a rotina abaixo:

## Rotina de Limpeza

Escanear o workspace procurando arquivos que não são mais úteis. Candidatos:

1. **`.ephemeral/scratch/`** — arquivos temporários com mais de 7 dias
2. **`.ephemeral/logs/`** — logs com mais de 14 dias
3. **`.ephemeral/notes/`** — notas avulsas já processadas ou obsoletas
4. **`vault/artefacts/`** — pastas de tasks já concluídas há mais de 30 dias (checar kanban Concluido)
5. **`vault/_agent/reports/`** — reports com mais de 30 dias
6. **`vault/sugestoes/`** — sugestões já revisadas (`reviewed: true` no frontmatter) com mais de 14 dias

## Processo

Para cada arquivo candidato:
1. Mover para `/workspace/.ephemeral/.trashbin/` mantendo path relativo (ex: `vault/sugestoes/foo.md` → `.trashbin/vault/sugestoes/foo.md`)
2. Registrar em `/workspace/.ephemeral/.trashlist` no formato:
   ```
   YYYY-MM-DD HH:MM | path/original | motivo
   ```
3. Listar no final o que foi arquivado

## Regras
- **NUNCA** arquivar: `CLAUDE.md`, `SOUL.md`, `SELF.md`, `flake.nix`, `configuration.nix`, `kanban.md`, `scheduled.md`, qualquer coisa em `modules/`, `stow/`, `projetos/`, `scripts/`
- **NUNCA** arquivar arquivos do vault que estejam linkados em cards ativos do kanban
- Na dúvida, **não arquivar** — melhor deixar lixo do que perder algo útil
- Mostrar preview do que vai ser arquivado e pedir confirmação antes de mover
