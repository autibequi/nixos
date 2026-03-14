# Monolito — Go Monolith Specialist

Invoque o agente Monolito para implementar, refatorar ou revisar código Go no monolito.

## Entrada
- `$ARGUMENTS`: descrição da tarefa (ex: "criar um novo handler para listar usuários", "refatorar o serviço de pagamentos", "fazer code review de pkg/handlers")

## Quando usar
- Implementar handlers, services, repositories, migrations
- Code review de código Go
- Refatorar estruturas existentes
- Debugar problemas de lógica de negócio
- Perguntas sobre arquitetura em camadas

## Capacidades do Agente
- **go-handler** — HTTP endpoints thin adapters
- **go-service** — business logic com dependency injection
- **go-repository** — data access layer
- **go-worker** — async jobs com retry
- **go-migration** — database schema changes (reversible)
- **review-code** — deep code review
- **make-feature** — end-to-end feature implementation

## Workflow
1. Descreva a tarefa em português ou inglês
2. O Monolito analisará o contexto
3. Implementará seguindo padrões de camadas (handler → service → repository → migration)
4. Entregará código testado + documentação de mudanças

Exemplo:
```
/monolito criar um novo handler POST /api/items que salva items no banco com validação de vertical
```

---

Invoque este comando quando precisar de ajuda com Go no monolito.
