---
name: code/peer-reviews
description: "Simula code review dos 5 peers do monolito (Washington, Pedro Castro, Molina, Marquesini, William). Cada dev tem perspectiva e prioridades distintas. Roda apos code/review ou standalone. Maximo de cobertura de bugs reais."
---

# code/peer-reviews — Review Simulado dos Peers

Simula o olhar de 5 desenvolvedores reais do monolito. Cada um revisa o diff com sua perspectiva, prioridades e manias documentadas abaixo.

## Argumentos

```
/code peer-reviews [--repo monolito|bo|front|all] [--dev all|washington|pedro|molina|marquesini|william]
```

Defaults: `--repo all`, `--dev all`

---

## Como rodar

1. Obter diff da branch atual vs main:
```bash
git diff origin/main -- . ':!vendor' ':!go.sum' ':!*.lock'
```

2. Ler cada arquivo novo/modificado por completo (nao apenas o diff — contexto importa)

3. Rodar as 5 perspectivas na ordem abaixo

4. Consolidar no final

---

## Perspectiva 1 — Washington (Arquiteto Meticuloso)

**Foco:** corretude semantica, separacao de camadas, consistencia de dados

Washington olha para:

### Camadas e Interfaces
- [ ] Cada service novo tem interface correspondente em `interfaces/`?
- [ ] Handler contem logica de negocio? (BLOCKER se sim — deve estar no service)
- [ ] Repository expoe metodo que deveria ser do service?
- [ ] Mock foi atualizado junto com a interface?

### Naming e Semantica
- [ ] Nomes de funcao sao longos e domain-descriptivos? (`GetCoursesByEcommerceItemIDs` > `GetCourses`)
- [ ] Maps usam prefixo descritivo? (`mpCoursesByID` > `coursesMap`)
- [ ] Variaveis de chave estao nomeadas? (`keyCurrentJobID` > string inline)
- [ ] Naming do metodo reflete exatamente o que faz? (ex: `ClearX` vs `SetX("")`)

### Error Handling
- [ ] Todo `if err != nil` tem log estruturado com campos relevantes?
- [ ] Usa `elogger.InfoErr` para erros esperados e `elogger.ErrorErr` para inesperados?
- [ ] Campos de log sao `.Str()`, `.Int()`, `.Any()` — nunca `Msgf` com interpolacao?
- [ ] Retry logic tem backoff e loga o `attempt`?
- [ ] `remaining <= 0` deveria ser `remaining == 0`? (off-by-one semantico)

### SQL e DB
- [ ] Query com `COALESCE` ou fallback tem join correto para soft delete?
- [ ] Tipo no Redis bate com o tipo no Go? (`int` vs `int64` causa scan error)
- [ ] `clause.OnConflict` esta correto para upsert?
- [ ] Raw SQL usa `utils.RemoveNestedWhitespaces()`?

### Observabilidade
- [ ] Todo metodo publico de service tem `defer newrelic.FromContext(ctx).StartSegment(...).End()`?
- [ ] Operacoes longas tem log de progresso com contadores `%d/%d`?

**Formato de comentario Washington:**
```
[Washington] <arquivo>:<linha>
  <observacao tecnica direta>
  suggestion: <codigo concreto se aplicavel>
```

---

## Perspectiva 2 — Pedro Castro (Operador Pragmatico)

**Foco:** funciona em producao? indexes? connection strings? degradacao graceful?

Pedro olha para:

### Producao e Infra
- [ ] Query nova tem indice correspondente? Qual o COST estimado?
- [ ] Connection strings, URLs, envs estao corretas para prod? (nao so sandbox)
- [ ] DLQ esta configurada? Worker que falha tem retry?
- [ ] Feature nova precisa de env var? Ja esta no SSM/secrets?

### Resiliencia
- [ ] Endpoint de UI retorna erro 500 ou degrada gracefully com dados parciais?
- [ ] Se um servico externo falha, o endpoint inteiro quebra ou so perde uma secao?
- [ ] Goroutine tem `recover()` com logging?
- [ ] Channel do Kafka esta sendo drenado? (memory leak se nao)

### Error Handling Pragmatico
- [ ] Erros que o usuario nao pode resolver estao sendo swallowed com fallback?
- [ ] Erros que o dev PRECISA ver estao sendo logados com contexto suficiente?
- [ ] Mensagens de erro no front sao claras? ("erro CONFLICT" vs "Item duplicado no curso")

### Checklist de Prod
- [ ] `log.Fatal` seguido de codigo que nunca executa? (redundancia)
- [ ] Dados salvos na coluna certa? (ex: `request` vs `response` em job_details)
- [ ] IDs estao sendo preenchidos em todos os campos? (ex: `course_id` vazio)

**Formato de comentario Pedro:**
```
[Pedro Castro] <arquivo>:<linha>
  <pergunta direta sobre comportamento em prod>
  se aplicavel: lista de itens faltando em bullet points
```

---

## Perspectiva 3 — Molina (Simplificador Cirurgico)

**Foco:** blast radius, indirection desnecessaria, seguranca de dados, bounds safety

> Observacao: Molina constroi arquitetura completa (entity/interface/repo/service) quando necessario — o "simplificador" se refere a remover abstracao que ja nao tem utilidade, nao a cortar corners estruturais.

Molina olha para:

### Simplificacao
- [ ] Feature flag que ja esta 100% ligada ainda esta no codigo? (remover)
- [ ] Abstraction layer que so tem uma implementacao e nunca vai ter outra? (simplificar)
- [ ] Indirection via `FeatureFlag[T, U]` quando um valor direto resolve? (eliminar)
- [ ] Constructor `New()` recebe dependencias que nao usa?

### Blast Radius
- [ ] Arquivo sendo deletado pode estar hardcoded em outro repo? (front, lambda, CDN)
- [ ] Mudanca de indice afeta queries existentes?
- [ ] Remocao de campo da API quebra consumers existentes?
- [ ] SDK bump precisa de PR isolado ou esta misturado com feature?

### Safety
- [ ] Array index apos `strings.Split` — length garantido >= N?
- [ ] `log.Fatal` esta sendo seguido de mais codigo? (nunca executa)
- [ ] Tabela pequena hoje, mas fullscan pode causar lock quando crescer? Paginar?
- [ ] Recursao pode ser substituida por fila/iteracao?

### Idiomatico
- [ ] Slice unpacking com `...` onde aplicavel?
- [ ] `json:"-"` em campo que nao deveria ser serializado?
- [ ] Constructor function `New(opts Options)` ao inves de struct literal no caller?

**Formato de comentario Molina:**
```
[Molina] <arquivo>:<linha>
  <observacao curta e direta — foco em seguranca ou simplificacao>
```

---

## Perspectiva 4 — Marquesini (Incrementalista Mobile)

**Foco:** request binding, Swagger, error tags, compatibilidade mobile

Marquesini olha para:

### Handler Quality
- [ ] Request struct tem `param`, `query`, `json` tags corretas?
- [ ] `validate:"required"` nos campos obrigatorios?
- [ ] Swagger annotations completas? (`@Summary`, `@Param`, `@Success`, `@Failure`, `@Router`)
- [ ] Error response tem `Tag` especifica? (`FORUM_ERROR`, `SOCIAL_ERROR_BAD_WORDS` > generico)

### Error Handling por Categoria
- [ ] Erros de dominio usam `errors.Is` com sentinels? (bad words, not found, conflict)
- [ ] Cada categoria retorna HTTP status diferente? (400 vs 404 vs 409 vs 500)
- [ ] Falha de side-effect (notificacao, analytics) eh non-fatal? (loga mas nao retorna erro)

### Mobile Compatibility
- [ ] Response retorna `[]` ao inves de `null` para arrays vazios?
- [ ] Campos opcionais tem `omitempty` na tag JSON?
- [ ] Breaking change na response shape? (mobile nao atualiza junto)

### Fire-and-Forget
- [ ] Background goroutine usa `appcontext.Background(ctx)` (nao o ctx original)?
- [ ] Timeout no context da goroutine? (`context.WithTimeout(ctx, time.Minute)`)
- [ ] `defer cancel()` presente?

**Formato de comentario Marquesini:**
```
[Marquesini] <arquivo>:<linha>
  <observacao sobre binding/swagger/mobile ou error category>
```

---

## Perspectiva 5 — William (Engenheiro de Qualidade)

**Foco:** testes, sentinel errors, seguranca, tipo nominal, mock quality

William olha para:

### Testes (inegociavel)
- [ ] Logica nova tem teste? (BLOCKER se nao — William bloqueia o PR)
- [ ] Service novo tem teste? (BLOCKER)
- [ ] Testes usam valores reais nos mocks? (`mock.Anything` em tudo = teste inutil)
- [ ] Testes validam o que NAO mudou? (campos imutaveis permanecem iguais)
- [ ] Teste de seguranca onde aplicavel? (anti-enumeration, rate limit)
- [ ] Integration test com DB real (`pgtest`) ao inves de mock de repo?

### Sentinel Errors
- [ ] Erro novo definido como `var Err* = errors.New(...)` no package?
- [ ] Handler usa `errors.Is(err, ...)` ao inves de comparar string?
- [ ] Mensagem de erro HTTP usa constante canonica? (`common_errors.ErrNotFound.Error()` > `err.Error()`)
- [ ] Detalhes internos nao vazam pela API? (mensagem do erro interno != mensagem HTTP)

### Goroutine Safety
- [ ] `errgroup` ao inves de goroutine raw com channel para fan-out? (padrao consistente em todos os PRs)
- [ ] Variaveis de erro dentro de goroutines tem nome unico? (`errGetFavorites`, `errGetCompleted` > `err` reusado) — padrao em PRs mais recentes (4425+), nem sempre presente nos mais antigos
- [ ] Escrita em map/slice compartilhado esta protegida? (ou feita antes do `eg.Wait()`)

### Tipo Nominal e Type Safety
- [ ] Magic string repetida deveria ser `type X string` com constantes?
- [ ] `SectionID`, `FastFilterEntityType` — discriminantes tipados?
- [ ] Nil check antes de dereference de ponteiro? (`*field` sem check)
- [ ] `MyDocsPdfID == nil || *MyDocsPdfID == ""` — ambos checados?

### Audit e Compliance
- [ ] Mutacao tem audit log? Falha do audit eh blocking?
- [ ] Swagger docs completo em handler novo?
- [ ] Contribuicao para `.coderabbit.yaml` se regra nova eh critica?

**Formato de comentario William:**
```
[William] <arquivo>:<linha>
  <observacao — tom amigavel mas firme>
  "manin, <sugestao concreta>"
```

---

## Consolidacao Final

Apos rodar as 5 perspectivas, consolidar:

```
================================================================
  PEER REVIEWS  <branch>   <data>
================================================================

-- Washington (Arquiteto) ----------------------------------------
  <N> comentarios

  1. [!!] <arquivo>:<linha> — <resumo>
  2. [XX] <arquivo>:<linha> — <resumo>
  ...

-- Pedro Castro (Operador) ---------------------------------------
  <N> comentarios

  1. [??] <arquivo>:<linha> — <pergunta sobre prod>
  ...

-- Molina (Simplificador) ----------------------------------------
  <N> comentarios

  1. [!!] <arquivo>:<linha> — <resumo>
  ...

-- Marquesini (Mobile) -------------------------------------------
  <N> comentarios

  1. [!!] <arquivo>:<linha> — <resumo>
  ...

-- William (Qualidade) -------------------------------------------
  <N> comentarios

  1. [XX] <arquivo>:<linha> — <resumo>  (BLOCKER: sem teste)
  ...

-- SUMARIO -------------------------------------------------------

  Blockers (XX):  <N>  — devem ser corrigidos
  Warnings (!!):  <N>  — merecem atencao
  Perguntas (??): <N>  — precisam de resposta
  Clean (ok):     <N>  — sem problemas

  Top 3 Riscos:
    1. <risco mais critico — qual dev levantou>
    2. <segundo risco>
    3. <terceiro risco>

  Veredicto: <APROVADO | COM RESSALVAS | MUDANCAS NECESSARIAS>
================================================================
```

### Indicadores
- `XX` = Blocker (William: sem teste, Washington: logica no handler, todos: bug real)
- `!!` = Warning (merece atencao mas nao bloqueia)
- `??` = Pergunta (Pedro: "funciona em prod?", precisa de resposta do autor)
- `ok` = Clean

### Criterio
- 0 blockers → APROVADO
- 0 blockers + 3+ warnings → COM RESSALVAS
- 1+ blockers → MUDANCAS NECESSARIAS

---

## Relacao com outras skills

```
/code peer-reviews  → este: 5 perspectivas simuladas, maximo de cobertura
/code review        → pipeline completo (JIRA + escopo + fluxo + validacao + veredito)
/code inspect       → inspecao leve rapida (checklist estatico)

Combinacao ideal:
  /code review         → entender O QUE mudou
  /code peer-reviews   → simular QUEM revisaria e O QUE cada um pegaria
```

---

## Regras

- Output INTEIRO no terminal — sem Chrome relay
- Ler arquivos COMPLETOS, nao apenas o diff — contexto de uso importa
- Cada dev DEVE ter pelo menos 1 comentario ou explicitar "sem observacoes"
- Manter o nome real do dev em cada comentario — o user conhece todos
- Nao inventar problemas — so reportar o que realmente aparece no codigo
- Se o diff for Vue/JS (bo/front), Pedro e Molina ainda revisam (infra/blast radius), mas William e Washington focam menos
