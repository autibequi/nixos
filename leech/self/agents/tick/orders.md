# Ordens do CTO — Tick

## Wake-All Noturno
janela: 01h-08h UTC (22h-05h BRT)
frequencia: 60min
quota_max: 85
quota_skip: 90
acao: acordar todos os agentes como subagentes

## Regras de Quota
- pct <= quota_max: sonnet + haiku
- pct > quota_max e <= quota_skip: haiku only
- pct > quota_skip: skip

## Historico de Ordens
- 2026-03-24: wake-all noturno ativado (Pedro)
