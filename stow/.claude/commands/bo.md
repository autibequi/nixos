# BoContainer — Vue 2 Backend Office Specialist

Invoque o agente BoContainer para implementar, refatorar ou revisar código Vue 2 no bo-container.

## Entrada
- `$ARGUMENTS`: descrição da tarefa (ex: "criar uma nova página de relatórios", "implementar filtro em tabela", "revisar componente de formulário")

## Quando usar
- Implementar novas páginas, rotas, componentes
- Criar/modificar services axios
- Code review de Vue 2
- Refatorar componentes existentes
- Perguntas sobre padrões Vue 2 Options API
- Dúvidas sobre Design System

## Capacidades do Agente
- **service** — axios-based API services
- **route** — hash routing com lazy loading
- **component** — presentational Vue 2 components
- **page** — page/view components com data loading
- **make-feature** — end-to-end feature (service → route → page → components)

## Workflow
1. Descreva a tarefa
2. O BoContainer analisará o contexto
3. Implementará seguindo padrões Vue 2 Options API
4. Entregará componentes com testes + documentação

## Convenções Chave
- **Service pattern** — class-based com axios injection, no hardcoding de headers
- **Route pattern** — hash routing, lazy loading com dynamic import
- **Component pattern** — Vue 2 Options API, props validation, scoped styles
- **Page pattern** — mounted hook para data loading, handle loading/error states
- **Design System** — prefixo `C` em componentes da `@estrategiahq/coruja-web-ui`
- **X-Vertical header** — sent automatically via axios interceptor

Exemplo:
```
/bo criar página nova de dashboard com gráficos e filtros de data
```

---

Invoque este comando quando precisar de ajuda com Vue 2 no bo-container.
