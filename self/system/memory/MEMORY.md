# Memory Index

- [feedback_zion_self_contained.md](feedback_zion_self_contained.md) — Zion must be self-contained: only use files from /nixos/self, never reference stow/.claude/ or external paths
- [project_dockerizer.md](project_dockerizer.md) — Sistema zion docker run/install/logs para monolito e outros serviços estratégia (inclui debug remoto)
- [feedback_docker_install.md](feedback_docker_install.md) — SSH mount, TTY, go mod download -x: lições do zion docker install
- [feedback_docker_debug.md](feedback_docker_debug.md) — dlv remoto em Docker + Cursor: 7 lições (binário path, ptrace, substitutePath, dlv dap vs exec)
- [reference_logs_location.md](reference_logs_location.md) — Logs em /workspace/logs/docker/<service>/ (service.log=runtime, test.log=testes); host: ~/.local/share/zion/logs/dockerized/
- [feedback_go_inspector.md](feedback_go_inspector.md) — go-inspector: não delegar ao agente Monolito (sem Agent tool interno), spawnar 6 inspetores diretamente do contexto principal
- [feedback_cursor_links.md](feedback_cursor_links.md) — Sempre usar cursor://file//home/pedrinho/... com :linha:col para links clicáveis de arquivos
- [feedback_worktree_obrigatorio.md](feedback_worktree_obrigatorio.md) — Sempre criar worktree isolado antes de implementar em qualquer repositório
- [feedback_zion_scripts_source.md](feedback_zion_scripts_source.md) — Scripts do container: fonte da verdade é zion/scripts/; scripts/ contém symlinks. Nunca editar scripts/ esperando afetar o container
- [feedback_autocommit.md](feedback_autocommit.md) — Nunca commitar automaticamente sem o usuário pedir; respeitar flag auto-commit
- [feedback_zion_cli_commands.md](feedback_zion_cli_commands.md) — Em zion host: sempre usar `zion stow`, `zion switch`, `zion man`. Nunca comandos raw.
