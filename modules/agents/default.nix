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
              maxWorkersFast = lib.mkOption { type = lib.types.ints.positive; default = 1; description = "Máximo de workers que o timer every10 (fast) pode levantar por execução."; };
              maxWorkersHeavy = lib.mkOption { type = lib.types.ints.positive; default = 1; description = "Máximo de workers que o timer every60 (heavy) pode levantar por execução."; };
              maxWorkersSlow = lib.mkOption { type = lib.types.ints.positive; default = 1; description = "Máximo de workers que o timer every240 (slow) pode levantar por execução."; };
            };
          };
          default = { };
          description = "Controle de workers CLAUDINHO (custos; fast/heavy/slow).";
        };
      };
    };
    default = { };
    description = "Opções de agentes (CLAUDINHO).";
  };
}
