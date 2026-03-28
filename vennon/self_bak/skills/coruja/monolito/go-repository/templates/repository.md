# Template: Repository Patterns

## Dois Estilos de Struct — use o padrão do app

**Estilo 1 — struct exported (ex: objetivos, ldi)**
```go
package mydomain

type Repository struct {
    db databases.Database
}

func NewMyRepository(db databases.Database) Repository {
    return Repository{db: db}
}
```

**Estilo 2 — struct unexported retornando interface (ex: pagamento_professores)**
```go
package mydomain

type repoImpl struct {
    db databases.Database
}

func NewMyRepository(db databases.Database) interfaces.MyRepositoryInterface {
    return &repoImpl{db: db}
}
```

Use o estilo já adotado pelo app em que está trabalhando.

## Obtendo Conexão (com suporte a transação)

Sempre verificar se há uma transação no contexto antes de usar a conexão padrão:

```go
func (r Repository) MyMethod(ctx context.Context, ...) (..., error) {
    var conn *gorm.DB
    tx := ctx.Value(appcontext.MyAppTxKey)
    if tx != nil {
        conn = tx.(*gorm.DB)
    } else {
        conn = r.db.GetConnection(ctx)
    }

    if conn == nil {
        return nil, errors.New("database connection is nil")
    }
    // ...
}
```

Se o repositório não precisa de transações, pode usar direto:
```go
conn := r.db.GetConnection(ctx)
```

## Queries com GORM

### Busca com filtros opcionais (padrão mais comum)

```go
func (r Repository) Search(ctx context.Context, search structs.MySearch) ([]*entities.MyItem, error) {
    q := r.db.GetConnection(ctx).Table("schema.my_table as t")

    if len(search.IDs) > 0 {
        q = q.Where("t.id IN ?", search.IDs)
    }
    if search.Name != "" {
        q = q.Where("t.name ILIKE ?", "%"+search.Name+"%")
    }
    if search.Active != nil {
        q = q.Where("t.active = ?", *search.Active)
    }

    q = q.Order("t.created_at DESC")

    var items []*entities.MyItem
    if err := q.Find(&items).Error; err != nil {
        elogger.ErrorErr(ctx, err).Stack().Msg("myRepo.Search")
        return nil, err
    }
    return items, nil
}
```

### Busca por ID único (mapear ErrRecordNotFound)

```go
func (r Repository) GetOne(ctx context.Context, id string) (entities.MyItem, error) {
    conn := r.db.GetConnection(ctx)

    var item entities.MyItem
    err := conn.Where("id = ? AND deleted_at IS NULL", id).First(&item).Error
    if err != nil {
        elogger.ErrorErr(ctx, err).Stack().Str("id", id).Msg("myRepo.GetOne")
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return entities.MyItem{}, structs.ErrMyItemNotFound  // erro de domínio
        }
        return entities.MyItem{}, err
    }
    return item, nil
}
```

### Create

```go
func (r Repository) Create(ctx context.Context, entity entities.MyItem) (entities.MyItem, error) {
    conn := r.db.GetConnection(ctx)
    if err := conn.Create(&entity).Error; err != nil {
        elogger.ErrorErr(ctx, err).Stack().Msg("myRepo.Create")
        return entities.MyItem{}, err
    }
    return entity, nil
}
```

### GORM Scopes (queries reutilizaveis)

Alguns apps usam scopes para encapsular logica de query reutilizavel. Scopes sao funcoes que retornam `func(db *gorm.DB) *gorm.DB` e sao aplicadas via `.Scopes()`:

```go
import "monolito/libs/databases/scopes"

func (r Repository) Search(ctx context.Context, filter queryparam.QueryParam) ([]*entities.MyItem, int, error) {
    q := r.db.GetConnection(ctx).Model(&entities.MyItem{})

    // Scopes padrao do monolito (quando o app usa queryparam)
    q = q.Scopes(
        scopes.BaseQueryParamScope(filter),   // aplica filtros genericos (where, like, in)
        scopes.PaginateScope(filter),          // aplica offset/limit
        scopes.OrderScope(filter, "name"),     // aplica order by (com fallback para "name")
    )

    var total int64
    // Count ANTES do paginate (para ter o total sem limit)
    countQ := r.db.GetConnection(ctx).Model(&entities.MyItem{}).Scopes(scopes.BaseQueryParamScope(filter))
    if err := countQ.Count(&total).Error; err != nil {
        return nil, 0, err
    }

    var items []*entities.MyItem
    if err := q.Find(&items).Error; err != nil {
        return nil, 0, err
    }
    return items, int(total), nil
}
```

**Quando usar scopes:** quando o app ja usa `queryparam.QueryParam` para parsear filtros da query string. Verificar os repos existentes do app — se usam scopes, seguir o padrao. Se nao usam, usar filtros manuais com `if`.

### Arrays PostgreSQL (pq.Array)

Para colunas do tipo `text[]` ou `uuid[]` no PostgreSQL:

```go
import "github.com/lib/pq"

// Na query
q = q.Where("t.tags && ?", pq.Array(search.Tags))  // overlap (tem algum dos valores)
q = q.Where("t.ids = ANY(?)", pq.Array(search.IDs)) // contains

// Na entity
type MyEntity struct {
    Tags pq.StringArray `gorm:"column:tags;type:text[]"`
}
```

### Paginação com Count

```go
func (r Repository) Search(ctx context.Context, search structs.MySearch) ([]*entities.MyItem, int, error) {
    q := r.db.GetConnection(ctx).Model(&entities.MyItem{}).Where("deleted_at IS NULL")
    // ...filtros...

    var total int64
    if err := q.Count(&total).Error; err != nil {
        return nil, 0, err
    }

    var items []*entities.MyItem
    if err := q.Offset((search.Page - 1) * search.PerPage).Limit(search.PerPage).Find(&items).Error; err != nil {
        return nil, 0, err
    }
    return items, int(total), nil
}
```
