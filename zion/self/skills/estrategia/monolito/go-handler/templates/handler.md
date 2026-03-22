# Handler — Anatomia Completa

## Anatomy of a Handler File

```go
package <package>

import (
    "net/http"

    "monolito/apps/bo/internal/handlers/common"
    "monolito/apps/bo/structs"
    "monolito/libs/appcontext"

    "github.com/estrategiahq/backend-libs/elogger"
    "github.com/estrategiahq/backend-libs/errors"
    "github.com/labstack/echo/v4"
)

// =============================================
// STRUCTS FICAM AQUI — NO TOPO DO ARQUIVO
// Antes de qualquer func. Não declarar dentro de funções.
// =============================================

// 1. REQUEST struct — define all inputs (query, path, body) com validate tags
type myEndpointRequest struct {
    ID    string   `param:"id"   validate:"required,uuid"`
    Page  int      `query:"page" validate:"required,min=1"`
    Types []string `query:"types" validate:"omitempty,dive,oneof=a b"`
}

// 2. RESPONSE struct — define o shape do Data retornado (se for complexo)
type myEndpointResponse struct {
    ID    string `json:"id"`
    Name  string `json:"name"`
}

// 3. SWAGGER — header obrigatório antes de todo handler
// @Summary     Descrição curta
// @Description Descrição longa
// @Tags        NomeTag
// @Accept      json
// @Produce     json
// @Param       id path string true "ID do recurso"
// @Success     200 {object} structs.HTTPResponse{Data=myEndpointResponse}
// @Failure     400 {object} errors.HTTPError
// @Failure     500 {object} errors.HTTPError
// @Router      /meu-recurso/{id} [get]
func (h Handler) MyEndpoint(c echo.Context) error {
    // 4. BIND
    params := myEndpointRequest{}
    if err := c.Bind(&params); err != nil {
        return errors.NewHTTPError(http.StatusBadRequest, err.Error(), "BIND_ERROR")
    }

    // 4a. Para slices com delimitador vírgula na query string:
    if err := echo.QueryParamsBinder(c).
        BindWithDelimiter("types", &params.Types, ",").
        BindError(); err != nil {
        return errors.HTTPError{Status: http.StatusBadRequest, Message: common.ErrInvalidRequest, Tag: "BIND_WITH_DELIMITER_ERROR"}
    }

    // 5. VALIDATE
    if err := c.Validate(params); err != nil {
        return errors.HTTPError{Status: http.StatusBadRequest, Message: err.Error(), Tag: "VALIDATION_ERROR"}
    }

    // 6. CONTEXT + VERTICAL (obrigatório — todo handler precisa resolver o vertical)
    ctx := c.Request().Context()
    vertical := appcontext.GetVertical(ctx)
    // ↑ O vertical é extraído do context via appcontext.GetVertical(ctx) — padrão dominante no codebase
    // ↑ (alternativa equivalente: appcontext.Vertical.GetStringValue(ctx) — menos comum)
    // ↑ Ele é a chave para acessar o service correto em AppsServices.<App>[vertical]
    // ↑ Sem vertical, o handler não consegue resolver qual service chamar.

    // 7. CHAMADA AO SERVIÇO — usa vertical como chave do mapa de services
    result, err := h.AppsServices.MinhaApp[vertical].MeuService.MinhaOperacao(ctx, ...)
    if err != nil {
        // SEMPRE logar o erro antes de retornar — essencial para debugging em produção
        elogger.ErrorErr(ctx, err).Msg("handler.MyEndpoint")
        return errors.HTTPError{Status: http.StatusInternalServerError, Message: common.ErrInternal, Tag: "INTERNAL_ERROR"}
    }

    // 8. RESPOSTA
    return c.JSON(http.StatusOK, structs.HTTPResponse{
        Data: result,
    })
}
```

## Erros Comuns a Evitar

1. **Structs dentro da função** — request/response structs devem ficar no **topo do arquivo**, fora de qualquer func. Nunca declarar structs inline.
2. **Esquecer o vertical** — todo handler que chama um service PRECISA de `vertical := appcontext.GetVertical(ctx)` para indexar o mapa `AppsServices.<App>[vertical]`. Sem isso, o handler não compila.
3. **Lógica de negócio no handler** — o handler só faz bind, validate, extrair vertical, chamar service e retornar. Toda lógica fica no service.
4. **Não logar erros** — antes de retornar um `errors.HTTPError`, sempre logar com `elogger.ErrorErr(ctx, err).Msg("handler.NomeDoEndpoint")`. Sem isso, erros em produção são invisíveis.

## Handler Struct (handler.go)

Cada pacote de handlers tem um `handler.go` com o struct e construtor:

```go
type Handler struct {
    AppsServices apps.Container
    Clients      *clients.Clients  // só se precisar de clients externos
}

func NewMeuHandler(appsServices apps.Container, clients *clients.Clients) Handler {
    return Handler{appsServices, clients}
}
```
