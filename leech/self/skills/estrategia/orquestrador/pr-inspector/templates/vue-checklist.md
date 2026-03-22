# Vue 2 / Nuxt 2 Inspection Checklist

Checklist para inspeção de código Vue 2 (BO Container) e Nuxt 2 (Front Student).

---

## Services

### BO Container
- [ ] Classe com `constructor(deps)` — recebe axios instance ou service dependencies
- [ ] Métodos async/await com try/catch
- [ ] Base URL configurada via constructor ou config
- [ ] Singleton exportado (ou factory)
- [ ] Sem lógica de negócio — apenas chamadas API

### Front Student
- [ ] Factory pattern `(axiosInstance, ctx) => ({ methods })`
- [ ] try/catch com `ctx.$log` para erro
- [ ] Registrado no plugin de services ou injection
- [ ] Sem estado interno (stateless factory)

## Routes

### BO Container
- [ ] Named views: `default` + `ServiceLayout`
- [ ] Lazy import: `() => import(/* webpackChunkName */ '...')`
- [ ] `routeRequiresPermission` se rota protegida
- [ ] Path em kebab-case
- [ ] Meta com `breadcrumb` se aplicável

### Front Student
- [ ] File-based routing via `pages/` structure
- [ ] `middleware` declarado se necessário
- [ ] `layout` especificado se não é default
- [ ] Path matches directory structure

## Components

### BO Container
- [ ] Vue 2 Options API (`data`, `methods`, `computed`, `watch`)
- [ ] Props com type e default
- [ ] Events emitidos com `$emit` (não callback props)
- [ ] Component name declarado explicitamente
- [ ] Scoped styles (`<style scoped>`)
- [ ] Sem acesso direto a `$store` em componentes presentational

### Front Student
- [ ] Separação presentational vs smart (container)
- [ ] Presentational: props in, events out, sem side effects
- [ ] Container: acessa store/services, passa dados aos presentational
- [ ] DesignSystem components usados quando disponível
- [ ] Tailwind classes (não CSS custom quando DS tem equivalente)

## Pages

### BO Container
- [ ] `q-page` wrapper (Quasar framework)
- [ ] `page-header` component para título e ações
- [ ] Services importados e usados via injection
- [ ] Screen type adequado (form, list, detail)
- [ ] Permissões checadas se necessário

### Front Student
- [ ] `asyncData` para fetch server-side
- [ ] Layout declarado
- [ ] Middleware declarado se necessário
- [ ] Delega lógica para container component
- [ ] Head/meta configurado para SEO

## Store (Vuex)

- [ ] State inicializado com valores default
- [ ] Mutations são síncronas
- [ ] Actions para operações async
- [ ] Getters para computed state
- [ ] Namespaced module (`namespaced: true`)
- [ ] Sem lógica de negócio complexa no store

## Cross-Cutting

- [ ] Sem `console.log` em código commitado
- [ ] Sem `debugger` statements
- [ ] Sem URLs hardcoded (usar config/env)
- [ ] Sem secrets/tokens em código
- [ ] Imports resolvem corretamente (paths existem)
- [ ] Sem dependências circulares entre módulos
- [ ] i18n usado se projeto tem multi-idioma

---

*Aplicar este checklist durante o Passo 4 da inspeção, adaptando ao repo (BO vs Front).*
