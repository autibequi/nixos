# Orquestrador — Cross-Repository Feature Conductor

Invoque o agente Orquestrador para coordenar features e bugs que envolvem múltiplos repositórios da Estrategia.

## Entrada
- `$ARGUMENTS`: tipo de tarefa + contexto (ex: "orquestrar FUK2-1234", "bug encontrado em checkout", "revisar PRs de pagamento")

## Quando usar
- Implementar feature que toca **monolito + bo-container + front-student**
- Bug fix que envolve múltiplos repos
- Code review de múltiplas PRs correlacionadas
- Reescrever histórico de commits com lógica clara
- Gerar changelog estruturado
- Retomar feature incompleta (descobrir blockers)

## Capacidades do Agente
- **orquestrar-feature** — Jira card → investigação → planejamento cross-repo → delegação a subagentes
- **changelog** — Gerar changelog estruturado por domínio e tópico
- **recommit** — Reescrever commit history (squash, reorder, narrative)
- **refinar-bug** — Investigar bug → reproduzir → propor estratégia → delegar
- **retomar-feature** — Resumir feature incompleta: estado atual + blockers + próximos passos
- **review-pr** — Code review cross-repo: consistência, arquitetura, testes

## Workflow
1. Descreva a tarefa (Jira ID, bug, ou tipo de review)
2. Orquestrador investiga o contexto
3. Cria arquivo central de controle (feature folder)
4. Delega a Monolito, BoContainer, FrontStudent conforme necessário
5. Coordena PRs, resolve conflitos, coordena merges
6. Entrega feature + changelog + relatório final

## Convenções Chave
- **Central feature folder** — `FUK2-<ID>/` na raiz do monorepo com `feature.md` + instruções por agente
- **Subagent files** — `feature.monolito.md`, `feature.bo.md`, `feature.frontstudent.md`
- **Tracking** — Orquestrador lê/atualiza feature.md; subagentes leem/atualizam seu próprio arquivo
- **Approval first** — Plan é apresentado ao user; implementação só começa após aprovação

Exemplo:
```
/orquestrador orquestrar FUK2-1234
```

---

Invoque este comando quando precisar coordenar work entre os 3 domínios.
