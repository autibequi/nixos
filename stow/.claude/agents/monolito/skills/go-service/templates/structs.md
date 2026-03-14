# Template: Method Signatures + Structs Organization

## Assinatura de Metodos

```go
// Padrao: ctx -> params obrigatorios identificadores -> options (modificadores opcionais)
Search(ctx context.Context, options structs.MySearchOptions) ([]structs.MyItem, int, error)
GetByID(ctx context.Context, id string) (*structs.MyItem, error)
Create(ctx context.Context, req structs.MyCreateRequest) (structs.MyItem, error)
Update(ctx context.Context, id string, req structs.MyUpdateRequest) (structs.MyItem, error)

// Options agrupam filtros, paginacao e qualquer parametro nao obrigatorio
// Pagination idealmente reutilizada entre metodos do mesmo pacote
```

## Structs — localizacao e organizacao

```
<app>/structs/
  my_domain.go         # request, response, options do mesmo dominio juntos
  pagination.go        # structs de paginacao reutilizaveis no app
```

```go
// <app>/structs/my_domain.go
type MySearchOptions struct {
    IDs        []string
    Name       string
    Page       int
    PerPage    int
    OrderBy    string
}

type MyCreateRequest struct {
    Name        string
    Description string
}

type MyItem struct {    // struct de retorno (resultado de ToDomain)
    ID          string `json:"id"`
    Name        string `json:"name"`
}
```
