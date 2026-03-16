# claudio CLI (bashly)

CLI unificado para o container Claude: `claudio run`, `claudio open` (OpenCode), `claudio shell`, etc.

## Instalação dinâmica

`stow/.local/bin/claudio` é um **symlink** para `claudinho/claudio-cli/claudio` (o script gerado). Depois do stow, `~/.local/bin/claudio` aponta para o script no repo — não precisa copiar nada. Basta rodar `bashly generate` (ou `make -C claudinho claudio-install`) após alterar o código; o mesmo arquivo é atualizado e o link continua válido.

## Desenvolvimento

- Editar `src/bashly.yml` e/ou `src/commands/*.sh`, `src/lib/compose_lib.sh`
- Regenerar: `make -C .. claudio-install` (só roda bashly generate; o symlink já aponta para o script)

## Testes

```bash
claudio --help
claudio run --help
claudio open --help
bashly validate
```

## Subcomandos

| Comando   | Alias        | Descrição |
|----------|---------------|-----------|
| run      | r (default)   | Claude no container (efêmero) |
| open     | opencode, code| OpenCode TUI |
| shell    | sh            | Bash no container |
| resume   | —             | Claude --resume |
| continue | cont          | Claude --continue |
| start    | —             | Sandbox persistente + Claude |
| openclaw | —             | OpenClaw gateway |

Flags globais: `--haiku`, `--opus`, `--instance ID`, `--rw`, `--ro`.
