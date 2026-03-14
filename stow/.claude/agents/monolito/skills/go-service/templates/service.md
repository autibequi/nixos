# Template: Service Struct + Constructor + Interface

## service.go — Struct e Construtor

```go
package myservice

import (
    "monolito/apps/<app>/interfaces"
    "monolito/apps/<app>/internal/repositories"
    "monolito/clients"
    "monolito/libs/databases"
)

// struct SEMPRE unexported
type serviceImpl struct {
    repos   *repositories.Container
    redis   databases.Cache
    clients *clients.Clients
    // apps *apps.Container  <- so se precisar chamar outros apps
}

// NewService retorna a INTERFACE publica, nunca o struct concreto
func NewService(
    repos *repositories.Container,
    redis databases.Cache,
    clients *clients.Clients,
) interfaces.MyServiceInterface {
    return &serviceImpl{repos: repos, redis: redis, clients: clients}
}
```

## Interface — onde declarar

```go
// <app>/interfaces/my_service.go  <- interface publica (outros apps usam)
type MyServiceInterface interface {
    Search(ctx context.Context, options structs.MySearchOptions) ([]structs.MyItem, int, error)
    Create(ctx context.Context, req structs.MyCreateRequest) (structs.MyItem, error)
    GetByID(ctx context.Context, id string) (*structs.MyItem, error)
}

// <app>/internal/interfaces/my_repo.go  <- interface interna (so repositorio interno)
type MyRepositoryInterface interface {
    Search(ctx context.Context, options structs.MySearchOptions) ([]*entities.MyItem, int, error)
    Create(ctx context.Context, entity entities.MyItem) (entities.MyItem, error)
}
```
