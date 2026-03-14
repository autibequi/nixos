# Agents — Invocar Especialista por Domínio

Invoque qualquer agente da Estrategia para trabalhar num domínio específico.

## Agentes Disponíveis

### Monolito — Go Monolith Specialist
```
/monolito <descrição da tarefa>
```
**Usa:** go-handler, go-service, go-repository, go-migration, go-worker, make-feature, review-code

**Quando:** Implementar handlers, services, repos, migrations, workers ou fazer code review de Go.

**Exemplo:**
```
/monolito criar um novo handler POST /api/items que salva items com validação de vertical
```

---

### BoContainer — Vue 2 Backend Office Specialist
```
/bo <descrição da tarefa>
```
**Usa:** service, route, component, page, make-feature

**Quando:** Implementar páginas, rotas, componentes Vue 2 ou fazer code review de Admin UI.

**Exemplo:**
```
/bo criar página nova de dashboard com gráficos e filtros de data
```

---

### Mesa — Nuxt 2 Student Portal Specialist
```
/mesa <descrição da tarefa>
```
**Usa:** service, route, component, page, make-feature

**Quando:** Implementar páginas, rotas, componentes Nuxt 2 ou fazer code review de Student Portal.

**Exemplo:**
```
/mesa criar página de listagem de cursos com filtros e paginação
```

---

### Orquestrador — Cross-Repository Feature Conductor
```
/orquestrador <tipo de tarefa> <contexto>
```
**Usa:** orquestrar-feature, changelog, recommit, refinar-bug, retomar-feature, review-pr

**Quando:** Implementar feature que toca múltiplos repos, bug fix cross-repo, code review de PRs correlacionadas, ou gerar changelog.

**Exemplo:**
```
/orquestrador orquestrar FUK2-1234
/orquestrador bug encontrado em checkout (toca back + front)
/orquestrador revisar PRs de pagamento
```

---

## Como Funciona

1. Você descreve a tarefa para o agente
2. Agente analisa o contexto + skills disponíveis
3. Agente implementa/revisa seguindo padrões de seu domínio
4. Agente entrega código testado + documentação

## Qual Agente Escolher?

| Tarefa | Agente |
|--------|--------|
| Go backend (handler, service, repo, migration, worker) | `/monolito` |
| Vue 2 admin UI (page, route, component, service) | `/bo` |
| Nuxt 2 student portal (page, route, component, container, service) | `/mesa` |
| Feature cross-repo OU bug em múltiplos repos OU code review multi-PR | `/orquestrador` |

---

**Escolha o especialista certo para o trabalho.**
