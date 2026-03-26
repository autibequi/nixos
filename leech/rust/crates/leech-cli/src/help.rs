//! Help text, banners, and man page — update this file when adding/changing CLI commands.
//!
//! DIRECTIVE: Any change to commands in main.rs MUST be reflected here.
//! Every subcommand gets a `before_help` with common usage examples (same visual pattern).

// ── Dim helper (used in all before_help blocks) ──────────────────────────────
// Format: command left-padded to 40 chars, dim description
// \x1b[2m = dim, \x1b[0m = reset, \x1b[35m = magenta

// ── Main ─────────────────────────────────────────────────────────────────────

pub const BANNER: &str = "\
\x1b[35m  ╦  ╔═╗╔═╗╔═╗╦ ╦\x1b[0m
\x1b[35m  ║  ║╣ ║╣ ║  ╠═╣\x1b[0m
\x1b[35m  ╩═╝╚═╝╚═╝╚═╝╩ ╩\x1b[0m  agent orchestration system

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech                          \x1b[2mnew session\x1b[0m
    leech --opus                   \x1b[2msession with Opus\x1b[0m
    leech continue                 \x1b[2mcontinue last session\x1b[0m

    leech runner mono start        \x1b[2mstart monolito\x1b[0m
    leech runner bo logs           \x1b[2mfollow bo-container logs\x1b[0m
    leech runner front shell       \x1b[2mshell in front-student\x1b[0m

    leech agents                   \x1b[2mlist agents\x1b[0m
    leech phone hermes o que tem hoje \x1b[2mligação para hermes\x1b[0m
    leech phone coruja analisa PR 42  \x1b[2mligação para coruja\x1b[0m
    leech phones lembra reunião 15h   \x1b[2massistente pessoal\x1b[0m
    leech ask coruja o que tem hoje \x1b[2moneshot question\x1b[0m
    leech run coruja               \x1b[2mrun agent now\x1b[0m
    leech tick                     \x1b[2mrun all due agents + tasks\x1b[0m

    leech status                   \x1b[2minteractive dashboard (TUI)\x1b[0m
    leech os switch                \x1b[2mapply NixOS config\x1b[0m
    leech stow                     \x1b[2mdeploy dotfiles\x1b[0m

\x1b[2m  ── full reference below · leech man for docs ─────────────\x1b[0m
";

pub const CLEANUP_AFTER: &str = "\
\x1b[33m  Aviso:\x1b[0m --reap envia SIGTERM ao \x1b[1mpai\x1b[0m dos zombies (só processos; \x1b[32mnão apaga arquivos\x1b[0m). \
Pede confirmação; use --yes para pular.

\x1b[2m  leech cleanup              lista pais com zombies bash (stack dev)\x1b[0m
\x1b[2m  leech cleanup --all        todos os pais\x1b[0m
\x1b[2m  leech cleanup --reap       resumo + confirmação + SIGTERM\x1b[0m
\x1b[2m  leech cleanup --reap -y    SIGTERM sem perguntar\x1b[0m
\x1b[2m  leech cleanup --min 5      só pais com ≥5 zombies\x1b[0m
";

pub const MAIN_AFTER: &str = "\
\x1b[2m  leech man          full documentation\x1b[0m";

// ── Runner ───────────────────────────────────────────────────────────────────

pub const RUNNER_BEFORE: &str = "\
\x1b[35m  runner\x1b[0m  \x1b[2mservice orchestration\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech runner mono start              \x1b[2mstart monolito (sand)\x1b[0m
    leech runner mono start --env=local  \x1b[2mstart with local env\x1b[0m
    leech runner mw start                \x1b[2mstart monolito-worker\x1b[0m
    leech runner mw start --debug        \x1b[2mworker com delve (port 2346)\x1b[0m
    leech runner bo logs                 \x1b[2mfollow bo-container logs\x1b[0m
    leech runner front shell             \x1b[2mshell in front-student\x1b[0m
    leech runner mono test               \x1b[2mmake test\x1b[0m
    leech runner bo install              \x1b[2mnpm install\x1b[0m
    leech runner mono stop               \x1b[2mstop + deps\x1b[0m
    leech runner front flush             \x1b[2mnuke everything\x1b[0m

\x1b[2m  aliases: mono, bo, front/fs, mw, rp\x1b[0m
\x1b[2m  actions: start stop restart logs shell test install build flush\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Agents ───────────────────────────────────────────────────────────────────

pub const AGENTS_BEFORE: &str = "\
\x1b[35m  agents\x1b[0m  \x1b[2magent management\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech agents                   \x1b[2mlist all agents\x1b[0m
    leech agents list --json       \x1b[2mJSON output\x1b[0m
    leech agents phone hermes      \x1b[2mtalk to hermes\x1b[0m
    leech agents phone coruja      \x1b[2mtalk to coruja\x1b[0m
    leech agents status coruja     \x1b[2mactivity log for coruja\x1b[0m
    leech agents status --json     \x1b[2mall activity as JSON\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Ask ──────────────────────────────────────────────────────────────────────

pub const ASK_BEFORE: &str = "\
\x1b[35m  ask\x1b[0m  \x1b[2moneshot question — to an agent or default model\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech ask como faço um for em bash?         \x1b[2msem agente — modelo padrão\x1b[0m
    leech ask coruja o que tem no radar hoje?   \x1b[2mcoruja responde\x1b[0m
    leech ask wiseman resume os insights        \x1b[2mwiseman responde\x1b[0m
    leech ask hermes status das tasks           \x1b[2mhermes responde\x1b[0m
    leech ask coruja -m sonnet analise profunda \x1b[2mforçar modelo\x1b[0m

\x1b[2m  Se o primeiro token for nome de agente conhecido: carrega contexto do agente.\x1b[0m
\x1b[2m  Caso contrário: envia pergunta direto ao modelo padrão (haiku).\x1b[0m
\x1b[2m  Roda headless com max-turns=10. Para conversa interativa: leech agents phone.\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Tasks ────────────────────────────────────────────────────────────────────

pub const TASKS_BEFORE: &str = "\
\x1b[35m  tasks\x1b[0m  \x1b[2mtask kanban\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech tasks                    \x1b[2mkanban: DOING / TODO / DONE\x1b[0m
    leech tasks log --json         \x1b[2mJSON output\x1b[0m
    leech tasks status             \x1b[2msame view\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── OS ───────────────────────────────────────────────────────────────────────

pub const OS_BEFORE: &str = "\
\x1b[35m  os\x1b[0m  \x1b[2mNixOS operations\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech os switch                \x1b[2mapply config now (nh os switch .)\x1b[0m
    leech os test                  \x1b[2mtest without applying\x1b[0m
    leech os boot                  \x1b[2mapply on next boot only\x1b[0m
    leech os build                 \x1b[2mbuild without switching\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Run ──────────────────────────────────────────────────────────────────────

pub const RUN_BEFORE: &str = "\
\x1b[35m  run\x1b[0m  \x1b[2mexecute agent or task\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech run hermes               \x1b[2mrun hermes now\x1b[0m
    leech run coruja -s 60         \x1b[2mrun coruja with 60 turns\x1b[0m
    leech run fix-login-bug        \x1b[2mrun task (fuzzy match)\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Worktree ─────────────────────────────────────────────────────────────────

pub const WORKTREE_BEFORE: &str = "\
\x1b[35m  worktree\x1b[0m  \x1b[2mgit worktrees\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech worktree                 \x1b[2mlist all worktrees\x1b[0m
    leech worktree monolito        \x1b[2monly monolito\x1b[0m
    leech worktree --json          \x1b[2mJSON output\x1b[0m

\x1b[2m  TUI: press 'w' in dashboard for interactive panel\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Status ───────────────────────────────────────────────────────────────────

pub const STATUS_BEFORE: &str = "\
\x1b[35m  status\x1b[0m  \x1b[2minteractive dashboard\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech status                   \x1b[2mopen TUI dashboard\x1b[0m
    leech status -t 2              \x1b[2mrefresh every 2s\x1b[0m
    leech status --json            \x1b[2mJSON snapshot\x1b[0m

\x1b[2m  TUI keys: j/k nav · Enter menu · a agents · w worktrees · q quit\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Tick ─────────────────────────────────────────────────────────────────────

pub const TICK_BEFORE: &str = "\
\x1b[35m  tick\x1b[0m  \x1b[2mauto-execute due agents + tasks\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech tick                     \x1b[2mrun all due agents + tasks\x1b[0m
    leech tick --dry-run           \x1b[2mshow what would run\x1b[0m
    leech tick -s 20               \x1b[2moverride steps to 20\x1b[0m

\x1b[2m  runs via systemd timer every 10min\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Stow ─────────────────────────────────────────────────────────────────────

pub const STOW_BEFORE: &str = "\
\x1b[35m  stow\x1b[0m  \x1b[2mdeploy dotfiles\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech stow                     \x1b[2mrestow (default)\x1b[0m
    leech stow adopt               \x1b[2madopt existing files\x1b[0m
    leech stow -r                  \x1b[2mrestow + reload waybar/hyprland\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Claude ───────────────────────────────────────────────────────────────────

pub const CLAUDE_BEFORE: &str = "\
\x1b[35m  claude\x1b[0m  \x1b[2mClaude API tools\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech claude usage             \x1b[2mAPI usage stats\x1b[0m
    leech claude token             \x1b[2mprint OAuth token\x1b[0m
    leech usage --waybar           \x1b[2mwaybar-formatted output\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Phone ─────────────────────────────────────────────────────────────────────

pub const PHONE_BEFORE: &str = "\
\x1b[35m  phone\x1b[0m  \x1b[2mligação telepática para um agente\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech phone oi tudo bem?              \x1b[2mmanda para hermes (default)\x1b[0m
    leech phone hermes o que tem no inbox \x1b[2mliga para hermes\x1b[0m
    leech phone coruja analisa o PR 42    \x1b[2mliga para coruja\x1b[0m
    leech phone wiseman o que é saudade?  \x1b[2mliga para wiseman\x1b[0m
    leech phone tamagochi te amo          \x1b[2mliga para tamagochi\x1b[0m

\x1b[2m  Roda headless com max-turns=10. Para sessão interativa: leech agents phone.\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

pub const PHONEBOOK_BEFORE: &str = "\
\x1b[35m  phonebook\x1b[0m  \x1b[2magenda de contatos dos agentes\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech phonebook                \x1b[2mlista todos os agentes\x1b[0m
    leech phonebook hermes         \x1b[2mcartão completo do hermes\x1b[0m
    leech phonebook coruja         \x1b[2mcartão completo da coruja\x1b[0m

\x1b[2m  aliases: contacts, agenda\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

pub const PHONES_BEFORE: &str = "\
\x1b[35m  phones\x1b[0m  \x1b[2massistente pessoal — lembretes, tasks, pesquisas\x1b[0m

\x1b[2m  ── common usage ──────────────────────────────────────────\x1b[0m

    leech phones lembra de ligar pra mãe amanhã às 10h \x1b[2mcria lembrete\x1b[0m
    leech phones adiciona task revisar PR do monolito   \x1b[2mcria task\x1b[0m
    leech phones qual a capital da Groenlândia?         \x1b[2mpergunta rápida\x1b[0m
    leech phones pesquisa como fazer deploy blue-green  \x1b[2mpesquisa\x1b[0m

\x1b[2m  Rota direta para o assistente pessoal. Registra lembretes/tasks no Obsidian.\x1b[0m

\x1b[2m  ─────────────────────────────────────────────────────────\x1b[0m
";

// ── Man page ─────────────────────────────────────────────────────────────────

/// Full GNU-style man page.
pub fn man_page() {
    println!("{BANNER}");
    println!("\x1b[1mNAME\x1b[0m");
    println!("    leech — agent orchestration system for NixOS\n");

    println!("\x1b[1mSYNOPSIS\x1b[0m");
    println!("    \x1b[1mleech\x1b[0m [COMMAND] [OPTIONS]\n");

    println!("\x1b[1mDESCRIPTION\x1b[0m");
    println!("    Leech manages Claude Code sessions, Docker services, NixOS config,");
    println!("    and an autonomous agent system that runs tasks on a schedule.\n");
    println!("    Without arguments, opens a new Claude Code session.\n");

    println!("\x1b[1mSESSION COMMANDS\x1b[0m");
    man_cmd("new, open, code", "[DIR] [--model M] [--host] [--ghost] [--opus|--haiku|--sonnet]",
        "Open new Claude Code session in container.\n\
         \x1b[0m                    --ghost: isolated session in obsidian/ghost/ (/workspace/ghost).");
    man_cmd("continue, cont", "[DIR] [--host]",
        "Continue the last session.");
    man_cmd("resume", "[DIR] [--resume ID] [--host]",
        "Resume a specific session by ID.");
    man_cmd("shell, sh", "[DIR] [--host]",
        "Bash shell inside the container.");
    man_cmd("leech, l", "[DIR] [--shell]",
        "Ephemeral session (auto-detect NixOS mount).");

    println!("\x1b[1mSERVICE COMMANDS\x1b[0m");
    man_cmd("runner, docker", "<SERVICE> <ACTION> [--env E] [--worktree W] [--debug]",
        "Docker Compose orchestration. Actions: start, stop, restart, logs,\n\
         \x1b[0m                    shell, test, install, build, flush.\n\
         \x1b[0m                    Aliases: mono, bo, front/fs, mw, rp.");
    man_cmd("worktree, wt", "[SERVICE] [--json]",
        "List git worktrees across services. Press 'w' in TUI for interactive panel.");

    println!("\x1b[1mAGENT COMMANDS\x1b[0m");
    man_cmd("agents, ag, a", "[SUBCOMMAND]",
        "Agent management. Subcommands: list, phone, status.");
    man_cmd("phone, call", "[AGENT] <MENSAGEM>",
        "Ligação telepática one-shot para um agente (default: hermes).\n\
         \x1b[0m                    Roda headless com max-turns=10. Mostra duração e quem ligou pra quem.");
    man_cmd("phonebook, contacts, agenda", "[NOME]",
        "Agenda de contatos — lista todos os agentes com emoji, modelo, clock e como ligar.\n\
         \x1b[0m                    Com nome: mostra cartão completo do agente.");
    man_cmd("phones", "<MENSAGEM>",
        "Assistente pessoal — cria lembretes/tasks no Obsidian, responde perguntas.\n\
         \x1b[0m                    Rota direta para o agente assistant (fallback: hermes).");
    man_cmd("run, r", "<NAME> [-s STEPS]",
        "Run an agent or task immediately. Creates card and executes via Claude CLI.");
    man_cmd("tick, auto", "[--dry-run] [-s STEPS]",
        "Execute all due agents + tasks (systemd timer, every 10min).");
    man_cmd("tasker", "[-s STEPS]",
        "Shortcut for 'leech run tasker' — process overdue tasks.");
    man_cmd("tasks, t", "[SUBCOMMAND]",
        "Task management. Subcommands: log, status.");

    println!("\x1b[1mHOST COMMANDS\x1b[0m");
    man_cmd("os", "<switch|test|boot|build>",
        "NixOS operations via nh.");
    man_cmd("stow", "[ACTION] [-r]",
        "Deploy dotfiles via GNU stow. Actions: restow (default), adopt, delete.");
    man_cmd("update, install", "",
        "Build and install leech CLI (cargo build --release).");
    man_cmd("set", "<ENGINE>",
        "Set default engine (claude, cursor, opencode).");

    println!("\x1b[1mDOCKER COMMANDS\x1b[0m");
    man_cmd("build", "[--danger]",
        "Build the leech Docker image.");
    man_cmd("down", "",
        "Stop compose containers.");
    man_cmd("shutdown", "",
        "Stop all containers + kill strays.");
    man_cmd("clean, gc, prune", "[-f]",
        "Remove stopped containers.");
    man_cmd("destroy", "",
        "Destroy containers + volumes + leech image (full reset).");

    println!("\x1b[1mTOOL COMMANDS\x1b[0m");
    man_cmd("status, st", "[-t SECS] [--json]",
        "Interactive TUI dashboard. --json for machine-readable snapshot.");
    man_cmd("usage", "[--waybar] [--json] [--refresh]",
        "Claude API usage stats.");
    man_cmd("token", "",
        "Print Claude OAuth access token.");
    man_cmd("inbox, ib", "",
        "Print inbox contents.");
    man_cmd("outbox, ob", "",
        "List outbox files.");
    man_cmd("hooks, hook", "[NAME] [-l] [KEY=VAL...]",
        "Execute or list Claude Code hooks.");
    man_cmd("relay", "[start|stop|status]",
        "Chrome DevTools Protocol relay.");
    man_cmd("sentinel, caffeine", "[start|stop|status|poweroff]",
        "Keep machine awake via systemd-inhibit (remote access).");
    man_cmd("git sandbox", "",
        "Stage all + commit with timestamp.");
    man_cmd("man", "",
        "This page.");

    println!("\x1b[1mTUI KEYBINDINGS\x1b[0m");
    println!("    j/k, ↑/↓     Navigate services");
    println!("    Enter        Open action menu");
    println!("    e            Cycle environment (sand/local/prod)");
    println!("    a            Agents panel");
    println!("    w            Worktrees panel");
    println!("    [/]          Scroll logs");
    println!("    q            Quit\n");

    println!("\x1b[1mENVIRONMENT\x1b[0m");
    println!("    LEECH_NIXOS_DIR    NixOS repo path (default: ~/nixos)");
    println!("    OBSIDIAN_PATH      Obsidian vault path");
    println!("    MONOLITO_DIR       Monolito project path");
    println!("    BO_CONTAINER_DIR   bo-container project path");
    println!("    FRONT_STUDENT_DIR  front-student project path\n");

    println!("\x1b[1mFILES\x1b[0m");
    println!("    ~/.leech                  Runtime config (KEY=VALUE)");
    println!("    ~/.config/leech/tui-envs  TUI environment persistence\n");

    println!("\x1b[1mSEE ALSO\x1b[0m");
    println!("    claude(1), docker-compose(1), nh(1), stow(1)\n");
}

fn man_cmd(name: &str, args: &str, desc: &str) {
    if args.is_empty() {
        println!("    \x1b[1mleech {name}\x1b[0m");
    } else {
        println!("    \x1b[1mleech {name}\x1b[0m {args}");
    }
    println!("                    {desc}\n");
}
