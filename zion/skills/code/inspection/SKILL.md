---
name: code/inspection
description: Inspeção leve de qualidade de código da branch atual — sem o peso interativo do pr-inspector. Verifica error handling, nil checks, contratos BFF/front, response shapes. Saída em markdown com indicadores por arquivo. Use para uma revisão rápida antes de abrir PR.
---

# code/inspection — Inspeção de Qualidade Leve

## Argumentos

```
/code:inspection [--repo monolito|bo|front|all] [--foco handlers|services|all]
```

Defaults: `--repo all`, `--foco all`

## Processo

### Passo 1 — Mapear arquivos tocados

Usar a lógica de `code/analysis/objects` para obter a lista de arquivos modificados por camada.
Focar apenas em arquivos com status `A` (novo) ou `M` (modificado) — ignorar `D`.

### Passo 2 — Inspecionar por tipo

#### Go — monolito (handlers e services)

Para cada arquivo `.go` modificado:

**Checklist handlers:**
- [ ] Tem `c.AbortWithStatusJSON` ou `c.JSON` em todos os caminhos de erro?
- [ ] Faz bind do request body com verificação de erro?
- [ ] Não tem lógica de negócio direta (delega para service)?
- [ ] Imports não têm pacotes não utilizados?
- [ ] `@Router`, `@Summary`, `@Tags` presentes se é handler público?

**Checklist services:**
- [ ] Retorna `error` em todos os paths de falha?
- [ ] Goroutines têm `WaitGroup` ou canal de controle?
- [ ] Nil checks antes de dereferênciar ponteiros?
- [ ] Contexto (`ctx`) passado até o repositório?

**Como inspecionar:**
```bash
# Verificar se há error handling em todos os retornos
grep -n 'if err' <arquivo>
# Verificar nil checks
grep -n 'if .* == nil\|if .* != nil' <arquivo>
# Verificar goroutines sem controle
grep -n 'go func\|go [A-Z]' <arquivo>
```

#### Vue/JS — bo-container e front-student

Para cada arquivo `.vue` ou `.js` modificado:

**Checklist Vue:**
- [ ] Props têm `type` e `default` ou `required`?
- [ ] Emits declarados com `defineEmits`?
- [ ] Sem `console.log` esquecido?
- [ ] Dados de API acessados com optional chaining (`?.`)?

**Checklist composables/services:**
- [ ] Chamadas de API têm try/catch?
- [ ] Loading state gerenciado?
- [ ] Contratos com BFF batem com o tipo esperado (verificar `LdiApiService.js`)?

```bash
# Verificar console.log esquecido
grep -n 'console\.log' <arquivo>
# Verificar optional chaining em dados externos
grep -n '\.\w\+\.' <arquivo> | grep -v '\?\.'
```

### Passo 3 — Output

Para cada arquivo inspecionado, emitir linha com status:

```
✅  apps/bff/main/ldi/get_course_structure.go    Handlers — OK
⚠️   services/course/build.go                    Services — goroutine sem WaitGroup (linha 45)
🔴  apps/bff/main/ldi/get_course.go              Handlers — error path sem AbortWithStatusJSON (linha 78)
```

**Legenda:**
- `✅` Tudo OK
- `⚠️` Aviso — não bloqueia mas merece revisão
- `🔴` Problema — deve ser corrigido antes do PR

### Passo 4 — Sumário final

```
── Sumário de Inspeção ───────────────────────────

  Total inspecionado: 14 arquivos
  ✅  OK:        9
  ⚠️  Avisos:    3
  🔴  Problemas: 2

  Arquivos com problema:
    - apps/bff/main/ldi/get_course.go (linha 78)
    - composables/Course.js (linha 32)
```

## Limitações

Esta é uma inspeção **estática leve** via grep/análise de padrões.
Para inspeção profunda e interativa com leitura completa dos arquivos,
usar `estrategia:mono:review-code` (monolito) ou `estrategia:orq:pr-inspector`.
