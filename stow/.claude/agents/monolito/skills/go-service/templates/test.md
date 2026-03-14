# Template: Test Structure

Package externo (`package myservice_test`), dependencias mockadas, foco em regras de negocio.

```go
package myservice_test

import (
    "testing"

    "monolito/apps/<app>/internal/repositories"
    appmocks "<monolito/apps/<app>/mocks"
    "monolito/libs/utils/testutils"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "github.com/stretchr/testify/require"
)

func TestMyService_Search(t *testing.T) {
    t.Parallel()

    ctx := testutils.Context(t)

    // 1. Mock dos repositorios
    myRepo := appmocks.NewMyRepositoryInterface(t)
    myRepo.On("Search", mock.Anything, mock.MatchedBy(func(opts structs.MySearchOptions) bool {
        return opts.PerPage == 20  // valida que logica de default foi aplicada
    })).Return([]*entities.MyItem{{ID: "1", Name: "Test"}}, 1, nil)

    // 2. Instanciar servico com repos mockados
    repos := &repositories.Container{MyRepo: myRepo}
    service := myservice.NewService(repos, nil, nil)

    // 3. Executar
    items, total, err := service.Search(ctx, structs.MySearchOptions{}) // PerPage=0, deve virar 20

    // 4. Assertions
    require.NoError(t, err)
    assert.Equal(t, 1, total)
    assert.Len(t, items, 1)
    assert.Equal(t, "Test", items[0].Name)

    myRepo.AssertExpectations(t)
}

func TestMyService_Search_RepoError(t *testing.T) {
    // Testar tambem o caminho de erro
    ...
}
```
