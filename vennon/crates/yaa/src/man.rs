use anyhow::Result;

pub fn show() -> Result<()> {
    print!(r#"
YAA(1)                      Yaa Manual                      YAA(1)

NAME
    yaa — session & agent orchestrator

SYNOPSIS
    yaa [OPTIONS] [DIR]
    yaa <COMMAND> [ARGS]

DESCRIPTION
    Yaa launches and manages AI coding sessions inside containers
    managed by vennon. It handles engine selection, model config,
    agent orchestration, and host utilities.

SESSION COMMANDS
    yaa [DIR]
        Start new session. DIR is mounted at /workspace/target.
        Defaults to ~/projects.

    yaa continue
        Continue the last session.

    yaa resume [SESSION_ID]
        Resume a specific session by ID, or pick from list.

    yaa shell
        Open interactive zsh shell inside the container.

SESSION FLAGS
    -e, --engine <ENGINE>
        Engine: claude, opencode, cursor.
        Default: session.engine from ~/.yaa.yaml

    -m, --model <MODEL>
        Model override: haiku, opus, sonnet, or full model ID.
        Default: models.<engine> from ~/.yaa.yaml

    --host
        Mount ~/nixos at /workspace/host (rw).
        Default: session.host from ~/.yaa.yaml

    --danger
        Bypass permissions. Claude: --dangerously-skip-permissions.
        Default: session.danger from ~/.yaa.yaml

AGENT COMMANDS
    yaa phone <AGENT> [MESSAGE]
        Call an agent. Opens interactive session with agent's
        prompt and model. Shows call duration on exit.

    yaa tick
        Run tick cycle (calls ticker agent).
        Equivalent to: yaa phone ticker "hora de rodar o ciclo"

TOOLS
    yaa usage [ENGINE]
        Show API usage for claude or cursor.

    yaa token [ENGINE]
        Print OAuth token for the engine (claude).

    yaa holodeck [start|stop|status]
        Chrome with CDP remote debugging on port 9222.

    yaa tmux <ACTION>
        Shared tmux session between host and container.
        Actions: serve, open, run, capture, status.

MANAGEMENT
    yaa init
        Create ~/.yaa.yaml with default configuration.

    yaa update
        Rebuild and install vennon + yaa + bridge.

CONFIGURATION
    ~/.yaa.yaml
        session.engine    — default engine (claude)
        session.host      — mount host by default
        session.danger    — bypass permissions by default
        models.claude     — default model for claude (opus)
        models.opencode   — default model for opencode
        models.cursor     — default model for cursor
        agents.model      — default agent model (haiku)
        agents.steps      — max turns for agents (30)
        paths.vennon      — vennon source dir
        paths.obsidian    — obsidian vault
        paths.projects    — default project dir
        paths.host        — host dir for --host flag
        tokens.*          — API tokens

COMPANION TOOLS
    vennon — container management (build, start, stop, flush)
    bridge — host utilities (stow, os) + TUI dashboard

SEE ALSO
    vennon(1), bridge(1)

"#);
    Ok(())
}
