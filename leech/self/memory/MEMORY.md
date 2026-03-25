# Memory Index

- [reference_ghostty_config.md](reference_ghostty_config.md) — Ghostty: light theme fix (catppuccin-latte), yazi images (image-storage-limit), gtk-single-instance, shell-integration

- [feedback_leech_self_contained.md](feedback_leech_self_contained.md) — Leech must be self-contained: only use files from /nixos/self, never reference stow/.claude/ or external paths
- [project_dockerizer.md](project_dockerizer.md) — Sistema leech docker run/install/logs para monolito e outros serviços estratégia (inclui debug remoto)
- [feedback_docker_install.md](feedback_docker_install.md) — SSH mount, TTY, go mod download -x: lições do leech docker install
- [feedback_docker_debug.md](feedback_docker_debug.md) — dlv remoto em Docker + Cursor: 7 lições (binário path, ptrace, substitutePath, dlv dap vs exec)
- [reference_logs_location.md](reference_logs_location.md) — Logs em /workspace/logs/docker/<service>/ (service.log=runtime, test.log=testes); host: ~/.local/share/leech/logs/dockerized/
- [feedback_go_inspector.md](feedback_go_inspector.md) — go-inspector: não delegar ao agente Monolito (sem Agent tool interno), spawnar 6 inspetores diretamente do contexto principal
- [feedback_cursor_links.md](feedback_cursor_links.md) — Sempre usar cursor://file//home/pedrinho/... com :linha:col para links clicáveis de arquivos
- [feedback_gtk_css_waybar.md](feedback_gtk_css_waybar.md) — GTK CSS @keyframes não funcionam no Waybar; usar só propriedades estáticas; animações requerem script externo
- [feedback_worktree_obrigatorio.md](feedback_worktree_obrigatorio.md) — Sempre criar worktree isolado antes de implementar em qualquer repositório
- [feedback_leech_scripts_source.md](feedback_leech_scripts_source.md) — Scripts do container: fonte da verdade é leech/scripts/; scripts/ contém symlinks. Nunca editar scripts/ esperando afetar o container
- [feedback_autocommit.md](feedback_autocommit.md) — Nunca commitar automaticamente sem o usuário pedir; respeitar flag auto-commit
- [feedback_leech_cli_commands.md](feedback_leech_cli_commands.md) — Com host_attached=1: sempre usar `leech stow`, `leech switch`, `leech man`. Nunca comandos raw.
- [feedback_container_readonly.md](feedback_container_readonly.md) — /home/claude/.claude/ é read-only no container — persistir APENAS em /workspace/self/ ou /workspace/obsidian/
- [feedback_timezone_container.md](feedback_timezone_container.md) — Container sem tzdata: usar TZ=UTC+3 (POSIX) para UTC-3 (Brasília), não America/Sao_Paulo
- [reference_leech_git_commit.md](reference_leech_git_commit.md) — Git repo do Leech em /workspace/host/.git — read-only no container, commit deve ser feito no host
- [reference_claude_process_nix.md](reference_claude_process_nix.md) — Processo Claude Code no nix = .claude-unwrapped; contar só linhas com pts/ no docker top
- [feedback_hyprctl_pixels.md](feedback_hyprctl_pixels.md) — monitors[].width = pixels físicos; activewindow.size[] = pixels lógicos — dividir pelo .scale antes de comparar frações
- [reference_hyprscroller_config.md](reference_hyprscroller_config.md) — Opções confirmadas/inexistentes do hyprscroller; workarounds shell para focus_wrap e colresize_no_wrap
- [project_agent_schedule_frontmatter.md](project_agent_schedule_frontmatter.md) — Cards em tasks/AGENTS/ precisam de frontmatter YAML com agent: ou são ignorados pelo tick
- [project_hermes_outbox_routing.md](project_hermes_outbox_routing.md) — Hermes roteia outbox tagado (para-*) e outbox livre (sem prefixo, inferência por conteúdo)
- [project_wiseman_inbox_tidy.md](project_wiseman_inbox_tidy.md) — Wiseman modo INBOX_TIDY: agrupa inbox por assunto em pastas (só com 3+), cria RESUMO.md
- [project_diretrizes.md](project_diretrizes.md) — DIRETRIZES.md em obsidian/bedrooms/: regras de todos os agentes; cada agente mantém sua seção; Wiseman fiscaliza
- [feedback_avatar_layout.md](feedback_avatar_layout.md) — Texto lateral ao avatar: máximo 2-3 palavras por linha; conteúdo real vai abaixo do code block
