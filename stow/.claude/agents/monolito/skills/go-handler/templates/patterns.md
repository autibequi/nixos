# Handler — Patterns de Validação, Erros, Vertical e Paginação

## Tags de Validação Comuns

```go
validate:"required"
validate:"required,uuid"
validate:"required,min=1,max=100"
validate:"omitempty,dive,oneof=subscription order"
validate:"omitempty,email"
```

## Erros HTTP

```go
// Com mensagem dinâmica (ex: do bind)
errors.NewHTTPError(http.StatusBadRequest, err.Error(), "TAG")

// Com mensagem fixa do common
errors.HTTPError{Status: http.StatusBadRequest, Message: common.ErrInvalidRequest, Tag: "TAG"}
errors.HTTPError{Status: http.StatusNotFound, Message: common.ErrNotFound, Tag: "NOT_FOUND"}
errors.HTTPError{Status: http.StatusInternalServerError, Message: common.ErrInternal, Tag: "INTERNAL_ERROR"}
```

## Resolução de Vertical (obrigatório em todo handler)

```go
// Extrair vertical do context — SEMPRE necessário para acessar services
ctx := c.Request().Context()
vertical := appcontext.GetVertical(ctx)

// Usar vertical como chave do mapa de services
result, err := h.AppsServices.MinhaApp[vertical].MeuService.Operacao(ctx, params.ID)
```

O `vertical` resolve qual instância do service usar (concursos, medicina, etc.). Sem ele, `AppsServices.<App>[vertical]` não compila. Todo handler que chama um service precisa dessa resolução.

## Resposta com Paginação

```go
return c.JSON(http.StatusOK, structs.HTTPResponse{
    Data: items,
    Meta: structs.Paginate{Page: params.Page, PerPage: params.PerPage, Total: total},
})
```
