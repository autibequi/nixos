# Template: Entity Definition

## Struct Basica

```go
// <app>/entities/my_item.go
package entities

import (
    "time"
    "monolito/apps/<app>/structs"
)

type MyItem struct {
    ID        string     `gorm:"column:id"`
    Name      string     `gorm:"column:name"`
    Active    bool       `gorm:"column:active"`
    // Campos opcionais/nullable → ponteiro
    DeletedAt *time.Time `gorm:"column:deleted_at"`
    ParentID  *string    `gorm:"column:parent_id"`
    // Campos obrigatórios/não-nulos → valor direto
    CreatedAt time.Time  `gorm:"column:created_at"`
    UpdatedAt time.Time  `gorm:"column:updated_at"`
}

// TableName define schema + tabela explicitamente
func (MyItem) TableName() string {
    return "schema_name.my_items"
}

// ToDomain converte entity → struct de domínio
// Chamado no serviço via lo.Map, nunca dentro do repo
func (e MyItem) ToDomain() structs.MyItem {
    return structs.MyItem{
        ID:     e.ID,
        Name:   e.Name,
        Active: e.Active,
    }
}
```

## Ponteiro vs Valor

- Use `*T` para campos que podem ser `NULL` no banco (nullable)
- Use `T` para campos `NOT NULL`

## Campos JSONB e JSONBArray

Para colunas do tipo `jsonb` no PostgreSQL, **nunca implementar `Scan`/`Value` manualmente**. Usar os tipos de `monolito/libs/databases/scanners`:

```go
import "monolito/libs/databases/scanners"

type MyItem struct {
    ID       string              `gorm:"column:id"`
    Metadata scanners.JSONB      `gorm:"column:metadata"`    // jsonb object
    Tags     scanners.JSONBArray `gorm:"column:tags"`        // jsonb array
}
```

**`scanners.JSONB`** — para `jsonb` que representa um objeto (`map[string]interface{}`). Expõe:
- `.Get(output interface{}) error` — deserializa para struct tipada
- `.Set(src interface{}) error` — serializa qualquer struct para o campo

**`scanners.JSONBArray`** — para `jsonb` que representa um array (`[]interface{}`). Mesmos métodos `.Get`/`.Set`.

```go
// Convertendo JSONB para struct tipada no ToDomain:
func (e MyItem) ToDomain() structs.MyItem {
    var meta structs.Metadata
    e.Metadata.Get(&meta)
    return structs.MyItem{
        ID:       e.ID,
        Metadata: meta,
    }
}
```

## Conversor Inverso (ToEntity)

Só criar se o serviço precisar converter struct → entity para persistir. Colocar no mesmo arquivo da entity:

```go
func MyItemFromDomain(s structs.MyCreateRequest) MyItem {
    return MyItem{
        Name:   s.Name,
        Active: true,
    }
}
```
