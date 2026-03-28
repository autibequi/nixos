# Leis do Sistema

> Se aplica a TODOS os agentes, sem excecao.
> Wiseman fiscaliza. Violacoes geram alerta inbox.

---

## Proibido

1. **Sem commits** — nunca `git commit/push` sem o CTO pedir explicitamente
2. **Sem invasao** — nunca escrever no bedroom/projeto de outro agente sem convite registrado
3. **Sem invencao** — nunca inventar dados, numeros ou fontes. Pesquisa real ou nada.
4. **Sem lixo** — nunca criar arquivos soltos fora de `bedrooms/`, `projects/`, `inbox/news/`, `inbox/ALERTA_*`
5. **Sem rollback** — cards so andam pra frente: TODO → DOING → DONE. Nunca voltar.
6. **Sem subpastas em tasks/** — outputs vao em `bedrooms/<nome>/` ou `projects/<nome>/`
7. **Sem pasta agents/ no vault** — perfis ficam em `bedrooms/<nome>/memory.md`

## Obrigatorio

8. **Timestamps UTC** — sempre `date -u +%Y-%m-%dT%H:%MZ`. Nunca datas relativas.
9. **Memory antes de encerrar** — atualizar `bedrooms/<nome>/memory.md` ANTES de reagendar
10. **Briefing primeiro** — ler o briefing do card ANTES de qualquer acao
11. **Boot completo** — ler `superego/` no inicio de cada ciclo
12. **VERIFY** — confirmar que artefatos existem (`ls -la <path>`) antes de reportar sucesso
13. **1 item por ciclo** — foco e profundidade, nao amplitude
14. **Self-scheduling** — reagendar sempre ao fim do ciclo, mesmo se falhar. Sem reagendamento = morto.
15. **Kanban so pra frente** — nunca mover card de DOING para TODO (rollback proibido)

## Quota

16. **< 70%** — normal
17. **>= 70%** — so haiku
18. **>= 85%** — pausar, so essencial
19. **>= 95%** — encerrar imediatamente, qualquer horario

## Penalidades (Wiseman aplica)

| Violacao | Acao |
|----------|------|
| Invasao de territorio | Alerta inbox + registrar em wiki/leech/insights.md |
| Sem reagendamento | Criar card de recuperacao +5min + alerta inbox |
| Memory desatualizada | Alerta inbox |
| Commit sem CTO | Alerta URGENTE ao CTO imediatamente |
| Kanban rollback | Alerta URGENTE + preservar estado |
| Arquivo solto em inbox/ | Mover para lugar correto ou deletar |
| Arquivo em vault/ direto | Mover para espaco correto + registrar em insights.md |
