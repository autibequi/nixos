# Template: Scenario Patterns

## Cenario: Proxy (sem logica)

Sempre criar o servico mesmo sendo proxy — para extensao futura e coesao. **Nao escrever teste** para metodos puramente proxy.

```go
func (s serviceImpl) CreateMany(ctx context.Context, arr []entities.MyItem) ([]structs.MyItem, error) {
    items, err := s.repos.MyRepo.CreateMany(ctx, arr)
    if err != nil {
        elogger.InfoErr(ctx, err).Msg("falha ao criar itens")
        return nil, err
    }
    return lo.Map(items, func(item entities.MyItem, _ int) structs.MyItem {
        return item.ToDomain()
    }), nil
}
```

## Cenario: Logica de Negocio (testar obrigatoriamente)

```go
func (s serviceImpl) Search(ctx context.Context, options structs.MySearchOptions) ([]structs.MyItem, int, error) {
    if options.PerPage <= 0 {
        options.PerPage = 20
    }

    items, total, err := s.repos.MyRepo.Search(ctx, options)
    if err != nil {
        elogger.ErrorErr(ctx, err).Stack().Msg("Search: falha no repositorio")
        return nil, 0, err
    }

    return lo.Map(items, func(item *entities.MyItem, _ int) structs.MyItem {
        return item.ToDomain()
    }), total, nil
}
```

## Cenario: Cache Redis

Chave sempre prefixada com `vertical`. Hash gerado a partir dos parametros de busca. Cache setado em background para nao bloquear a response.

```go
func (s serviceImpl) Search(ctx context.Context, options structs.MySearchOptions) ([]structs.MyItem, error) {
    // 1. Montar chave com vertical + hash dos parametros
    hashKey := utils.ToHash256(map[string]any{
        "ids":  options.IDs,
        "name": options.Name,
    })
    redisKey := fmt.Sprintf("%s:my-resource:search:%s", s.vertical, hashKey)

    // 2. Tentar cache primeiro
    var cached []structs.MyItem
    if err := s.redis.GetData(ctx, redisKey, &cached); err == nil && len(cached) > 0 {
        return cached, nil
    }

    // 3. Buscar no banco
    items, err := s.repos.MyRepo.Search(ctx, options)
    if err != nil {
        elogger.ErrorErr(ctx, err).Stack().Msg("MyService.Search: repo error")
        return nil, err
    }

    if len(items) == 0 {
        return []structs.MyItem{}, nil
    }

    result := lo.Map(items, func(item *entities.MyItem, _ int) structs.MyItem {
        return item.ToDomain()
    })

    // 4. Setar cache em background (nao bloqueia a response)
    async.Background(ctx, func(bgCtx context.Context) {
        if err := s.redis.SetData(bgCtx, redisKey, result, 24*time.Hour); err != nil {
            elogger.ErrorErr(bgCtx, err).Stack().Msg("MyService.Search: cache set error")
        }
    })

    return result, nil
}
```

**Convencao de chave:** `<vertical>:<recurso>:<operacao>:<hash>` — ex: `medicina:courses:search:a3f9...`

**TTL comuns:** 24h para dados estaticos, 1h para dados mutaveis, sem TTL so para dados que invalidam explicitamente.

## Cenario: Orquestracao (chama outros apps)

```go
// Pode chamar servicos de outros apps via apps.Container
func (s serviceImpl) BuildReport(ctx context.Context, id string) (*structs.Report, error) {
    course, err := s.apps.LDI[s.vertical].CourseService.GetByID(ctx, id)
    ...
}

// NUNCA acessar repositorio de outro app diretamente
// s.apps.LDI[vertical].repos.Course.GetByID(...)  <- proibido
```

## Cenario: Transacao (operacoes que precisam de atomicidade)

Quando o metodo faz multiplas escritas que devem ser atomicas, usar o pattern de transacao. A transacao e gerenciada pelo repositorio (BeginTransaction/CommitTransaction/RollbackTransaction) e propagada via context.

```go
func (s serviceImpl) CreateWithItems(ctx context.Context, req structs.CreateRequest) (structs.MyEntity, error) {
    defer newrelic.FromContext(ctx).StartSegment("myService.CreateWithItems").End()

    // 1. Iniciar transacao — retorna um ctx novo com a tx embutida
    txCtx, err := s.repos.MyRepo.BeginTransaction(ctx)
    if err != nil {
        elogger.ErrorErr(ctx, err).Stack().Msg("myService.CreateWithItems: begin tx")
        return structs.MyEntity{}, err
    }

    // 2. Operacoes dentro da transacao (todas usam txCtx)
    entity, err := s.repos.MyRepo.Create(txCtx, entities.MyEntity{Name: req.Name})
    if err != nil {
        s.repos.MyRepo.RollbackTransaction(txCtx)
        return structs.MyEntity{}, err
    }

    for _, item := range req.Items {
        _, err := s.repos.ItemRepo.Create(txCtx, entities.Item{ParentID: entity.ID, Value: item.Value})
        if err != nil {
            s.repos.MyRepo.RollbackTransaction(txCtx)
            return structs.MyEntity{}, err
        }
    }

    // 3. Commit
    if _, err := s.repos.MyRepo.CommitTransaction(txCtx); err != nil {
        return structs.MyEntity{}, err
    }

    return entity.ToDomain(), nil
}
```

**Regras:**
- `BeginTransaction` retorna um `context.Context` novo com a tx embutida (via `appcontext.<App>TxKey`)
- Todos os repos que recebem esse ctx usam a mesma transacao automaticamente (via `getTx(ctx)`)
- Se der erro em qualquer passo, fazer `RollbackTransaction` antes de retornar
- Nao esquecer de `CommitTransaction` no final

## NewRelic Tracing (obrigatorio em todo metodo de servico)

Todo metodo de service deve ter a primeira linha como `defer newrelic.FromContext(ctx).StartSegment(...)`. Isso e essencial para monitoramento de performance em producao.

```go
func (s serviceImpl) GetByID(ctx context.Context, id string) (*structs.MyItem, error) {
    defer newrelic.FromContext(ctx).StartSegment("myService.GetByID").End()
    // ... resto do metodo
}
```

**Convencao de nome do segment:** `<packageName>.<MethodName>` — ex: `goalService.Create`, `courseService.Search`

O import necessario e:
```go
"github.com/newrelic/go-agent/v3/newrelic"
```

## Logging

```go
// Erro esperado (user error, not found, conflito) — InfoErr, sem Stack
elogger.InfoErr(ctx, err).Str("course_id", id).Msg("curso nao encontrado")

// Erro inesperado (falha de infra, panic catch) — ErrorErr COM Stack
elogger.ErrorErr(ctx, err).Stack().Msg("contexto: erro critico com stack")

// NUNCA usar Msgf com interpolacao — sempre campos estruturados
// ERRADO: elogger.Info(ctx).Msgf("buscando curso %s do user %s", courseID, userID)
// CERTO:
elogger.Info(ctx).Str("course_id", courseID).Str("user_id", userID).Msg("buscando curso")

// Progresso em operacoes longas (batch, migration):
elogger.Info(ctx).Int("current", cnt).Int("total", len(items)).Msg("processando lote")
```

## Sentinel Errors (padrao do time)

Definir erros de dominio como variaveis package-level. Nunca comparar por string.

```go
// No package structs/ do dominio:
var (
    ErrPDFNotFound      = errors.New("pdf not found")
    ErrContentIsNotPDF  = errors.New("content is not a pdf")
    ErrItemDuplicated   = errors.New("item already exists in course")
)

// No service — retornar o sentinel:
if pdf == nil {
    return entities.Chapter{}, ErrPDFNotFound
}

// No handler — mapear sentinel para HTTP com errors.Is:
if errors.Is(err, ldiStructs.ErrPDFNotFound) {
    return errors.HTTPError{Status: http.StatusNotFound, Message: common_errors.ErrNotFound.Error(), Tag: "PDF_NOT_FOUND"}
}
// NUNCA expor err.Error() direto na response — vaza detalhes internos
```

## Concorrencia com errgroup (padrao do time)

Sempre usar `errgroup` para fan-out. Nunca goroutine raw com channel.
Variaveis de erro DEVEM ter nome unico dentro de cada goroutine (evita bug de closure).

```go
var favoriteIDsMap, completedIDsMap map[string]bool
eg := errgroup.Group{}

eg.Go(func() error {
    favorites, errGetFavorites := h.getFavoriteLdiIds(ctx)
    if errGetFavorites != nil {
        elogger.InfoErr(ctx, errGetFavorites).Msg("falha ao buscar favoritos")
        return errGetFavorites
    }
    favoriteIDsMap = favorites // write apos retorno, antes do eg.Wait()
    return nil
})

eg.Go(func() error {
    completed, errGetCompleted := h.getCompletedLdiIds(ctx)
    if errGetCompleted != nil {
        return errGetCompleted
    }
    completedIDsMap = completed
    return nil
})

if err := eg.Wait(); err != nil {
    // single error path
}
```

## Empty slice vs nil (critico para mobile)

```go
// API consumers (especialmente mobile) esperam [] e nao null
if chapters == nil {
    chapters = []ChapterDetails{}
}

// Ao retornar listas vazias apos filtro:
return []structs.MyItem{}, nil  // nunca return nil, nil
```

## Retry com backoff

```go
maxAttempts := 3
var lastErr error
for attempt := 1; attempt <= maxAttempts; attempt++ {
    if err := s.repo.Increment(ctx, id); err != nil {
        lastErr = err
        elogger.InfoErr(ctx, err).Int("attempt", attempt).Msg("retry increment")
        time.Sleep(time.Duration(attempt) * 2 * time.Second)
        continue
    }
    return nil
}
return lastErr
```
