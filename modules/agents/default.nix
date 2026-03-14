# =============================================================================
# agents — Módulo de agentes (CLAUDINHO timers + agent-container / ClaudeOS)
# =============================================================================
# core.nix     = systemd timers, runners, cleanup no host
# agent-container/ = ambiente do container (packages.nix + flake.nix)
# =============================================================================

{ imports = [ ./core.nix ]; }
