---
name: code/test/plan
description: Gera plano de testes a partir do diff da branch atual. Analisa serviços, interfaces e structs modificadas, levanta todos os métodos testáveis e produz relatório com cenários Happy/Sad/Weird agrupados por serviço, com tags de tipo e marcação de prioridade. Testes são pensados como black box — independente de conhecer a implementação.
---

# code:test:plan — Plano de Testes a partir do Diff

Gera um plano completo de testes baseado nas mudanças da branch atual. Não escreve código — produz o mapa de "o que testar e por quê" antes de qualquer implementação.

## Passo 1 — Coletar o diff

```bash
# fork point
FORK=$(git merge-base origin/main HEAD)

# arquivos modificados
git diff $FORK..HEAD --stat

# diff completo por camada
git diff $FORK..HEAD -- 'apps/**/services/**' 'apps/**/structs/**' 'apps/**/entities/**' 'apps/**/interfaces/**'
```

Ler o diff completo dos arquivos de serviço, structs e interfaces. **Ler o código, não só o diff** — entender o contrato de cada método.

## Passo 2 — Mapear o que mudou

Classificar cada arquivo modificado em:

| Camada | O que levantar |
|---|---|
| `interfaces/` | Métodos adicionados ou com assinatura alterada |
| `structs/` | Tipos novos, funções puras novas, campos novos em tipos existentes |
| `entities/` | Campos novos que afetam serialização/deserialização |
| `services/` | Métodos novos, métodos com lógica alterada |
| `repositories/` | Queries novas (geralmente testadas via service) |
| `handlers/` | Só listar — perguntar ao dev antes de incluir no plano |

## Passo 3 — Detectar impacto indireto

Serviços que **não foram modificados** mas usam interfaces/structs alteradas também devem ser listados como candidatos.

```bash
# quais arquivos importam os pacotes de interfaces modificados
grep -r "interfaces\." apps/ --include="*.go" -l | grep -v "_test.go" | grep -v "mock"

# quais services usam os structs novos
grep -r "TocRebuildOpts\|CachedContentTree\|ErrTocRebuildRunning" apps/ --include="*.go" -l
```

Se encontrar serviços impactados indiretamente que tenham lógica de negócio relevante → **pausar e informar ao dev antes de continuar**.

## Passo 4 — Listar métodos testáveis com protótipos

Para cada serviço afetado (direto ou indireto), listar os métodos com assinatura completa:

```
SERVICE: course.Service
  func (s Service) BuildAndSaveContentTree(ctx context.Context, courseID string) (structs.CachedContentTreeResponse, error)
  func (s Service) CheckTocRebuildConflict(ctx context.Context, opts ldiStructs.TocRebuildOpts) error
  ...

STRUCTS PUROS (sem mock necessário):
  func ConvertToCachedTOC(courseID string, nodes []DocumentTocComplete) CachedContentTreeResponse
  func ToContentTree(course *entities.Course) (*CachedContentTreeResponse, bool)
```

Métodos privados só aparecem se testáveis indiretamente — indicar o método público que os exercita.

## Passo 5 — Gerar os cenários de teste

Para cada método, gerar cenários nos três grupos abaixo. **Regra fundamental: os cenários devem ser pensados como black box — como alguém que conhece apenas o contrato (inputs/outputs/erros documentados), sem saber como foi implementado. Incluir testes que podem quebrar por uso incorreto, edge cases de contrato e comportamentos que o dev pode assumir que funcionam mas não foram testados.**

### Grupos

**Happy path** — comportamento esperado com inputs válidos
**Sad path** — inputs inválidos, erros de dependências, estados impossíveis
**Weird path** — edge cases, comportamentos de fronteira, prioridades implícitas, deduplicação, campos em branco dentro de structs válidas

### Tags obrigatórias no início de cada cenário

| Tag | Quando usar |
|---|---|
| `[VALID DATA]` | fluxo completo com dados corretos |
| `[IF NIL]` | input nil |
| `[IF EMPTY]` | input vazio (slice, string, struct zerada) |
| `[IF NIL RETURN NIL]` | nil em campo opcional causa retorno nil/zero |
| `[CHECK NIL ID]` | ID vazio dentro de struct válida |
| `[VALID JSON]` | deserialização de JSON válido |
| `[INVALID JSON]` | JSON malformado ou tipo errado |
| `[ERROR PROPAGATE]` | erro de dependência sobe sem modificação |
| `[PARTIAL FAIL]` | falha em um item de loop não aborta os demais |
| `[SKIP REPO]` | não consulta repositório quando não necessário |
| `[CACHE HIT]` | retorno vem do cache sem ir ao banco |
| `[SKIP CACHE]` | flag/opção ignora cache e vai ao banco |
| `[PRIORITY X]` | quando múltiplos campos preenchidos, X tem prioridade |
| `[DEDUP]` | resultado não contém duplicatas |
| `[CONFLICT X]` | detecta conflito do tipo X |
| `[FLATTEN]` | estrutura hierárquica é achatada corretamente |
| `[CHECK FLAG]` | campo booleano derivado de condição |
| `[FALLBACK]` | usa valor alternativo quando campo principal ausente |
| `[IF NIL TRACKER]` | service/tracker nil → não pânica |
| `[MULTI STATUS]` | múltiplos status diferentes ao mesmo tempo |
| `[LOOP CONTINUE]` | continua iteração após falha parcial |
| `[NO SIDE EFFECT]` | operação idempotente / sem efeito colateral extra |

Novas tags podem ser criadas se nenhuma existente encaixar — manter no formato `[SCREAMING_SNAKE]`.

### Formato de cada cenário

```
- `[TAG]` descrição em linguagem natural do cenário → resultado esperado
```

Marcar cada cenário com um color code de prioridade:

| Cor | Quando usar |
|---|---|
| 🔴 | Crítico — cobre o caminho principal da feature, erros que chegam ao usuário (409/500/dados corrompidos), ou comportamentos fáceis de implementar errado (prioridades, deduplicação, nil checks aninhados) |
| 🟡 | Interessante — edge case que vale testar, comportamento de fronteira não óbvio, cobertura secundária de uma regra importante |
| 🔵 | Meh — cobertura defensiva, caso improvável, comportamento trivial que provavelmente nunca quebra na prática |

## Passo 6 — Verificar se há regra de negócio fora de serviços

Antes de finalizar, verificar se handlers, structs puras ou outros pacotes contêm lógica de negócio **não coberta por serviços**:

```bash
git diff $FORK..HEAD -- 'apps/**/handlers/**' | grep "^+" | grep -v "^+++" | grep -E "if |switch |for "
```

Se houver lógica relevante em handlers → **informar ao dev com lista dos handlers** e perguntar se quer incluir no plano antes de fechar o relatório.

## Passo 7 — Emitir o relatório

### Formato do relatório

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SERVICE: <package>.<Type>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func (s Type) MethodName(args) (returns)

Happy
- `[TAG]` cenário → resultado [🔴]

Sad
- `[TAG]` cenário → resultado [🔴]

Weird
- `[TAG]` cenário → resultado [🔴]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 STRUCTS PURAS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func FunctionName(args) returns

Happy / Sad / Weird
...
```

Ao final, emitir lista de recomendadas:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 🔴 RECOMENDADAS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ServiceName
  🔴 [TAG]  descrição curta do cenário
  🔴 [TAG]  ...
```

## Regras

- **Black box obrigatório**: cenários baseados no contrato (assinatura + erros documentados), não na implementação lida. Se a implementação tiver um bug, o teste deve falhar — esse é o objetivo.
- **Não evitar testes que quebram**: testes que falharão com a implementação atual são válidos e devem aparecer. Quem decide se o teste ou o código está errado é o dev.
- **Métodos privados**: não listar diretamente — indicar qual método público os exercita.
- **Foco em serviços**: handlers só entram se o dev confirmar ou se houver lógica de negócio explícita neles.
- **Structs puras**: sempre incluir — são os testes mais baratos de escrever e mais frágeis de ignorar.
- **Não gerar código de teste**: este plano é input para `code/tdd` ou para o dev escrever manualmente.
