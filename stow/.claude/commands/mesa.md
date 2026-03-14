# Mesa — Nuxt 2 Student Portal Specialist

Invoque o agente Mesa (Front Student) para implementar, refatorar ou revisar código Nuxt 2 no portal de estudos.

## Entrada
- `$ARGUMENTS`: descrição da tarefa (ex: "criar página de cursos", "implementar container de perfil", "revisar componente de card")

## Quando usar
- Implementar páginas, rotas, containers, componentes Nuxt 2
- Criar/modificar services axios
- Code review de código Vue 2 + Nuxt
- Refatorar componentes existentes
- Perguntas sobre asyncData vs mounted
- Dúvidas sobre Container vs Component pattern
- Integração com Vuex
- Design System

## Capacidades do Agente
- **service** — axios-based API services
- **route** — Nuxt file-based routing (pages/ auto-maps)
- **component** — presentational dumb components (pure render)
- **page** — page/view components com asyncData (SSR) + mounted (client)
- **make-feature** — end-to-end feature (service → page → container → components)

## Workflow
1. Descreva a tarefa
2. O agente Mesa analisará o contexto
3. Implementará seguindo padrões Nuxt 2 com Container vs Component
4. Entregará código com testes + documentação

## Convenções Chave
- **Service pattern** — class-based com axios injection
- **Route pattern** — Nuxt file-based routing (pages/ directory auto-maps)
- **asyncData vs mounted** — asyncData para SSR data, mounted para client-only
- **Container pattern** — smart components que fetch data (mounted hook)
- **Component pattern** — dumb presentational (props in, events out)
- **Vuex** — auth state, user profile, global UI state only
- **Design System** — prefixo `C` em componentes da `@estrategiahq/coruja-web-ui`
- **Middleware** — route guards para auth/permissions

Exemplo:
```
/mesa criar página de listagem de cursos com filtros e paginação
```

---

Invoque este comando quando precisar de ajuda com Nuxt 2 no portal de estudos.
