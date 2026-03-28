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

## Error Handling por Categoria (padrao do time)

Diferenciar erros por dominio usando sentinel errors + `errors.Is`. Cada categoria retorna HTTP status e Tag distintos.

```go
// Erros de dominio com sentinel:
if errors.Is(err, socialStructs.ErrCommentHasBadWords) {
    return c.JSON(http.StatusBadRequest, structs.HTTPResponse{
        Err:  &errors.HTTPError{Message: "Comentario contem palavras restritas", Tag: "SOCIAL_ERROR_BAD_WORDS"},
        Meta: badwords,
    })
}
if errors.Is(err, ldiStructs.ErrPDFNotFound) {
    return errors.HTTPError{Status: http.StatusNotFound, Message: common_errors.ErrNotFound.Error(), Tag: "PDF_NOT_FOUND"}
}

// NUNCA expor err.Error() na response — usar constantes canonicas:
// ERRADO: Message: err.Error()
// CERTO:  Message: common_errors.ErrNotFound.Error()
```

## Side-effects Non-Fatal (padrao do time)

Falha de notificacao, analytics, cache invalidation NAO deve falhar a request principal.

```go
// Notificacao falhou — loga mas nao retorna erro
if err := h.deleteNotification(ctx, request.CommentId); err != nil {
    elogger.Error(ctx).Err(err).Str("comment_id", request.CommentId).
        Msg("falha ao deletar notificacao — non-fatal")
    // NAO retorna — continua o fluxo
}

// Cache invalidation em background
async.Background(ctx, func(bgCtx context.Context) {
    h.invalidateCache(bgCtx, courseID)
})
```

## Request Struct Inline (padrao Marquesini/William)

Definir struct de request inline no handler quando so eh usado ali.

```go
func (h Handler) DeleteComment(c echo.Context) error {
    type deleteCommentRequest struct {
        ForumId   string `param:"forum_id" validate:"required"`
        CommentId string `param:"comment_id" validate:"required"`
    }
    ctx := c.Request().Context()
    var request deleteCommentRequest
    if err := c.Bind(&request); err != nil {
        elogger.Error(ctx).Err(err).Str("tag", "BIND_ERROR").
            Msg("bff.forumHandler.DeleteComment.Bind")
        return errors.HTTPError{Status: http.StatusBadRequest, Message: common_errors.ErrBadRequest.Error(), Tag: "BIND_ERROR"}
    }
    // ...
}
```

## Fire-and-Forget com Context Isolado

Background goroutine DEVE usar context derivado, NAO o original (que cancela quando a request termina).

```go
func (h Handler) addCourseToRecentActivities(ctx context.Context, course ldiEntities.Course) {
    userID := appcontext.GetUserID(ctx)
    go func() {
        ctx := appcontext.Background(ctx) // context independente da request
        ctx, cancel := context.WithTimeout(ctx, time.Minute)
        defer cancel()
        // ... operacao async
    }()
}
```

## Tipo Nominal para Discriminantes (padrao William)

Magic strings repetidas devem virar tipos nominais com constantes.

```go
type SectionID string
const (
    SectionIDGoals            SectionID = "goals"
    SectionIDLdisByDiscipline SectionID = "ldisByDiscipline"
    SectionIDTrails           SectionID = "trails"
)

type FastFilterEntityType string
const (
    FastFilterEntityLDI   FastFilterEntityType = "ldi"
    FastFilterEntityTrail FastFilterEntityType = "trail"
)
```
