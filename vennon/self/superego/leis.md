# Leis do Sistema

> Se aplica a TODOS os agentes, sem excecao.
> Wiseman fiscaliza. Violacoes geram alerta inbox.

---

## Proibido

1. **Sem commits** — nunca `git commit/push` nem `jj describe/new/push` sem o CTO pedir explicitamente
2. **JJ obrigatorio** — SEMPRE usar jj. NUNCA usar `git branch`, `git checkout`, `git worktree`, `git stash`, `git merge`. Equivalentes: `jj bookmark`, `jj edit`, `jj new`, `jj rebase`. Se repo nao tem `.jj`: inicializar com `jj git init --colocate` antes de qualquer operacao.
3. **Sem invasao** — nunca escrever no bedroom/projeto de outro agente sem convite registrado
4. **Sem invencao** — nunca inventar dados, numeros ou fontes. Pesquisa real ou nada.
5. **Sem lixo** — nunca criar arquivos soltos fora de `bedrooms/`, `projects/`, `inbox/news/`, `inbox/ALERTA_*`
6. **Sem rollback** — cards so andam pra frente: TODO → DOING → DONE. Nunca voltar.
7. **Sem subpastas em tasks/** — outputs vao em `bedrooms/<nome>/` ou `projects/<nome>/`
8. **Sem pasta agents/ no vault** — perfis ficam em `bedrooms/<nome>/memory.md`

## Obrigatorio

9. **Timestamps UTC** — sempre `date -u +%Y-%m-%dT%H:%MZ`. Nunca datas relativas.
10. **Memory antes de encerrar** — atualizar `bedrooms/<nome>/memory.md` ANTES de reagendar
11. **Briefing primeiro** — ler o briefing do card ANTES de qualquer acao
12. **Boot completo** — ler `superego/` no inicio de cada ciclo
13. **VERIFY** — confirmar que artefatos existem (`ls -la <path>`) antes de reportar sucesso
14. **1 item por ciclo** — foco e profundidade, nao amplitude
15. **Self-scheduling** — reagendar sempre ao fim do ciclo, mesmo se falhar. Sem reagendamento = morto.
16. **Kanban so pra frente** — nunca mover card de DOING para TODO (rollback proibido)

## Quota

17. **< 70%** — normal
18. **>= 70%** — so haiku
19. **>= 85%** — pausar, so essencial
20. **>= 95%** — encerrar imediatamente, qualquer horario

## Penalidades (Wiseman aplica)

| Violacao | Acao |
|----------|------|
| Invasao de territorio | Alerta inbox + registrar em wiki/vennon/insights.md |
| Sem reagendamento | Criar card de recuperacao +5min + alerta inbox |
| Memory desatualizada | Alerta inbox |
| Commit sem CTO | Alerta URGENTE ao CTO imediatamente |
| Kanban rollback | Alerta URGENTE + preservar estado |
| Arquivo solto em inbox/ | Mover para lugar correto ou deletar |
| Arquivo em vault/ direto | Mover para espaco correto + registrar em insights.md |
