# avaliar-repositorio — Memória

## Resumo
Task recorrente que varre o repositório NixOS em busca de bugs, melhorias e oportunidades de limpeza. Cria tasks concretas em `pending/` quando encontra algo actionable.

## Histórico de execuções

### 2026-03-13T11:44Z
- **O que fiz:** Primeira execução. Analisei git status, git log, arquivos .nix modificados recentemente, makefile, scripts/, tasks/ existentes.
- **O que aprendi:**
  - `scripts/api-usage.sh` não existe mas é referenciado em 3 targets do makefile — bug concreto
  - `melhorar-automacoes` já tem proposta V3 bem detalhada, não duplicar
  - `usage-api-7d` e `usage-api-30d` fora do `.PHONY` (item menor)
  - `home-manager` no flake.nix poderia ter `inputs.nixpkgs.follows` para consistência
- **Decisões:** Criar task `criar-api-usage-sh` (bug concreto). Não criar segunda task — demais itens já cobertos ou muito cosméticos.
- **Próximos passos:** Na próxima execução, checar se `criar-api-usage-sh` foi concluída; investigar módulos NixOS desabilitados (gnome, cosmic, kde) que podem ser removidos.
