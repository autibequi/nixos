# Catálogo de Padrões Suspeitos

Padrões que indicam problemas em PRs, especialmente vibe-coded. **Este arquivo evolui com o tempo** — após cada inspeção, adicionar novos padrões descobertos.

---

## Go — Padrões Suspeitos

### Hallucinated Imports
**Sinal:** Import path que não existe no monolito
**Risco:** Código não compila; se compila, pode importar pacote errado
**Verificação:** `ls <import_path>` no repo

### Missing Error Handling
**Sinal:** `err` atribuído mas nunca checado (`result, err := fn()` sem `if err != nil`)
**Risco:** Erros silenciados, comportamento inesperado em produção
**Verificação:** Grep por `err :=` ou `err =` seguido de uso de `result` sem check

### N+1 Queries em Loops
**Sinal:** Query dentro de `for range` loop
**Risco:** Performance degradada exponencialmente com volume
**Verificação:** Procurar chamadas de repo/DB dentro de loops

### Missing NewRelic Segments
**Sinal:** Método de service sem `defer txn.StartSegment(...).End()`
**Risco:** Sem observabilidade em produção
**Verificação:** Comparar com services existentes que usam NewRelic

### Goroutines Sem Sync
**Sinal:** `go func()` sem `sync.WaitGroup`, `errgroup`, ou channel
**Risco:** Race conditions, goroutine leaks
**Verificação:** Procurar `go func` e verificar mecanismo de sync

### Missing Nil Checks
**Sinal:** Dereference de ponteiro sem nil check
**Risco:** Panic em produção
**Verificação:** Procurar `*ptr` ou `ptr.Field` sem `if ptr != nil`

### SQL Injection
**Sinal:** String interpolation em queries (`fmt.Sprintf("SELECT ... WHERE id = %s", id)`)
**Risco:** SQL injection
**Verificação:** Procurar `fmt.Sprintf` com SQL keywords

### Copy-Paste Blocks
**Sinal:** Blocos >10 linhas com >80% similaridade
**Risco:** Bugs duplicados, manutenção frágil
**Verificação:** Diff visual entre blocos similares

### Dead Code
**Sinal:** Função/método definido mas nunca chamado
**Risco:** Confusão, manutenção desnecessária
**Verificação:** Grep pelo nome da função no repo

### Breaking Interface Changes
**Sinal:** Método adicionado/removido/modificado em interface pública
**Risco:** Quebra compilação de outros apps que implementam a interface
**Verificação:** Grep por implementações da interface em outros apps

### Vertical Hardcoded
**Sinal:** ID de vertical como constante ou string literal
**Risco:** Funciona para uma vertical, quebra outras
**Verificação:** Procurar IDs numéricos ou strings de vertical hardcoded

---

## Vue/Nuxt — Padrões Suspeitos

### Hallucinated Component Imports
**Sinal:** `import Component from '@/components/...'` com path inexistente
**Risco:** Build falha ou componente não renderiza
**Verificação:** `find` pelo nome do componente no repo

### Missing Prop Validation
**Sinal:** Props declarados como `Array` ou `Object` sem `type` ou `validator`
**Risco:** Runtime errors difíceis de debugar
**Verificação:** Checar props definition no bloco `<script>`

### Direct DOM Manipulation
**Sinal:** `document.querySelector`, `this.$el.innerHTML`, `document.getElementById`
**Risco:** Conflito com reatividade do Vue, memory leaks
**Verificação:** Grep por `document.` no código do componente

### Memory Leaks
**Sinal:** `addEventListener` sem `removeEventListener` no `beforeDestroy`
**Risco:** Memory leak progressivo
**Verificação:** Contar `addEventListener` vs `removeEventListener`

### Unused Computed Properties
**Sinal:** Computed declarado mas nunca referenciado no template
**Risco:** Código morto, confusão
**Verificação:** Grep pelo nome do computed no template

### Mixin Conflicts
**Sinal:** Mixin e componente definem data/methods/computed com mesmo nome
**Risco:** Mixin silenciosamente sobrescrito
**Verificação:** Comparar nomes entre mixin e componente

### Missing Async Error Handling
**Sinal:** `async` method sem try/catch
**Risco:** Promise rejection não tratada
**Verificação:** Procurar `async` sem `try` no mesmo escopo

---

## Geral — Sinais de Vibe-Code

### TODO/FIXME/HACK Comments
**Sinal:** Comentários `// TODO`, `// FIXME`, `// HACK` deixados por AI
**Risco:** Trabalho incompleto commitado
**Verificação:** Grep por `TODO|FIXME|HACK`

### Over-Abstraction
**Sinal:** Factory-of-factory, strategy pattern para 1 caso, interface com 1 implementação + 0 testes
**Risco:** Complexidade sem benefício
**Verificação:** Contar implementações de cada interface

### Only Happy Path
**Sinal:** Nenhum `if err`, nenhum caso de erro, nenhum edge case testado
**Risco:** Falha em produção no primeiro input inesperado
**Verificação:** Contar error handling vs total de funções

### Inconsistent Patterns Within PR
**Sinal:** Um handler usa pattern A, outro usa pattern B, no mesmo PR
**Risco:** Indica geração sem contexto compartilhado
**Verificação:** Comparar structure de handlers/services entre si

### Generic Commit Messages
**Sinal:** "implement feature", "add changes", "update code", "fix stuff"
**Risco:** Indica commit único sem review incremental
**Verificação:** Ler `git log` do PR

### Excessive Comments
**Sinal:** Comentário explicando o óbvio (`// loop through items`, `// return result`)
**Risco:** Sinal de AI generation sem curadoria
**Verificação:** Ratio comentários/código

### Phantom Dependencies
**Sinal:** `import` ou `require` de pacote não listado em go.mod/package.json
**Risco:** Build falha em ambiente limpo
**Verificação:** Verificar go.mod ou package.json

---

*Última atualização: 2026-03-15 — criação inicial*
*Atualizar este arquivo após cada inspeção de PR.*
