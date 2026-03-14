# Template: Interface + Container Wiring

## Interface do Repositório

```go
// <app>/internal/interfaces/my_repo.go
package interfaces

import (
    "context"
    "monolito/apps/<app>/entities"
    "monolito/apps/<app>/structs"
)

type MyRepositoryInterface interface {
    Create(ctx context.Context, entity entities.MyItem) (entities.MyItem, error)
    GetOne(ctx context.Context, id string) (entities.MyItem, error)
    Search(ctx context.Context, search structs.MySearch) ([]*entities.MyItem, int, error)
    Update(ctx context.Context, entity entities.MyItem) (entities.MyItem, error)
    Delete(ctx context.Context, id string) error
    // Transações (só se necessário):
    BeginTransaction(ctx context.Context) (context.Context, error)
    CommitTransaction(ctx context.Context) (context.Context, error)
    RollbackTransaction(ctx context.Context) (context.Context, error)
}
```

## Container — Registrar o Novo Repositório

```go
// <app>/internal/repositories/container.go
type Container struct {
    MyDomain  interfaces.MyRepositoryInterface
    OtherRepo interfaces.OtherRepositoryInterface
}

func NewContainer(db databases.Database) Container {
    return Container{
        MyDomain:  mydomain.NewMyRepository(db),
        OtherRepo: otherdomain.NewOtherRepository(db),
    }
}
```

## Erros de Domínio

Mapear erros técnicos do GORM para erros de domínio:

```go
// <app>/structs/errors.go  (ou no arquivo do domínio)
var ErrMyItemNotFound = errors.New("item não encontrado")
```

```go
if errors.Is(err, gorm.ErrRecordNotFound) {
    return entities.MyItem{}, structs.ErrMyItemNotFound
}
```
