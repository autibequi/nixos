# =============================================================================
# agents — Módulo de agentes (CLAUDINHO options + scheduler)
# =============================================================================
# Options de controle de workers. Scheduler em ./scheduler.nix.
# agent-container/ = ambiente do container (packages.nix + flake.nix)
# =============================================================================

{ config, lib, pkgs, ... }:
{
  imports = [
    ./scheduler.nix
  ];

  options.local.agents = lib.mkOption {
    type = lib.types.submodule {
      options = {
        claudinho = lib.mkOption {
          type = lib.types.submodule {
            options = {
              maxConcurrentWorkers = lib.mkOption { type = lib.types.ints.positive; default = 1; description = "Máximo de containers worker (Claude) rodando ao mesmo tempo. 1 = só um por vez (controle de custo)."; };
              tickBudgetSeconds = lib.mkOption { type = lib.types.ints.positive; default = 540; description = "Budget em segundos por tick do scheduler (default 540 = 9min de 10min tick)."; };
            };
          };
          default = { };
          description = "Controle de workers CLAUDINHO (custos; scheduler unificado).";
        };
      };
    };
    default = { };
    description = "Opções de agentes (CLAUDINHO).";
  };
}
