---
name: code/github-evaluate
description: "Avalia um desenvolvedor GitHub analisando PRs e review comments reais. Produz relatorio completo no inbox do Obsidian com 10 dimensoes, arquetipos e comparativo com benchmarks do time Estrategia."
---

# code/github-evaluate — Avaliacao de Desenvolvedor via GitHub

Analisa PRs e review comments de um desenvolvedor para mapear seu estilo, pontos fortes e areas de crescimento. Produz relatorio completo no inbox do Obsidian.

## Argumentos

```
/code:github-evaluate <github-username> [--repo org/repo] [--prs N] [--lang go|ts|any] [--level L3|L4|L5|staff]
```

- `github-username`: obrigatorio — handle do GitHub
- `--repo`: repo especifico (default: detecta do diretorio atual)
- `--prs`: quantidade de PRs para analisar (default: 10, min: 5, max: 20)
- `--lang`: linguagem principal esperada (default: detecta dos PRs)
- `--level`: nivel esperado para calibrar o comparativo (default: L4)

---

## Pipeline de Avaliacao

### Fase 1 — Coleta de PRs

```bash
# Listar PRs merged do dev (mais recentes primeiro)
gh pr list --author <username> --state merged --limit <N> --json number,title,additions,deletions,changedFiles,createdAt,mergedAt

# Se --repo nao especificado, usar repo do cwd
```

Filtrar PRs com pelo menos 20 linhas de adicao (ignorar bumps de dependencia, typo fixes).

### Fase 2 — Leitura de Diffs

Para cada PR selecionado:

```bash
gh pr diff <number> -- ':!vendor' ':!go.sum' ':!*.lock' ':!package-lock.json'
```

Ler o diff completo. Anotar:
- Quais camadas foram tocadas (handler, service, repository, entity, test, migration, config)
- Tamanho e escopo do PR
- Padrao de commit (atomico vs monolito)

### Fase 3 — Leitura de Review Comments

```bash
# Reviews que o dev RECEBEU
gh pr view <number> --json reviews,comments

# Reviews que o dev FEZ em PRs de outros
gh api "/repos/{owner}/{repo}/pulls/comments?sort=created&direction=desc&per_page=100" | jq '[.[] | select(.user.login == "<username>")]'
```

Capturar:
- Tom e profundidade dos comentarios que FAZ
- Como responde a feedback que RECEBE
- Se bloqueia PRs (CHANGES_REQUESTED) e por quais motivos

### Fase 4 — Analise por Dimensao

Avaliar o dev em **10 dimensoes** com evidencia direta dos PRs:

#### 1. Estrutura de Codigo
- Separacao de camadas (handler/service/repo)
- Arquivos por funcao vs arquivos monoliticos
- Interfaces: extrai preventivamente ou so quando precisa?
- Tamanho dos PRs: atomico, incremental ou big-bang?

#### 2. Naming
- Convencao (PascalCase, camelCase, snake_case — consistente?)
- Descritivo vs curto: `GetCoursesByEcommerceItemIDs` vs `GetCourses`
- Prefixos de maps, keys, erros
- Nomes de testes (descritivos ou genericos?)

#### 3. Error Handling
- Propaga ou swallows? Quando cada um?
- Usa sentinel errors? (`var ErrNotFound = errors.New(...)`)
- `errors.Is` / `errors.As` para decisao no handler?
- Logging: estruturado (`.Str`, `.Int`) ou interpolado (`Msgf`)?
- Normaliza mensagens HTTP ou expoe `err.Error()`?

#### 4. Testing
- Escreve testes junto com codigo novo?
- Unit vs integration vs ambos?
- Table-driven tests?
- Valida o que NAO mudou?
- Mock values significativos vs `mock.Anything`?
- Testes de seguranca (anti-enumeration, auth bypass)?

#### 5. Idiomas da Linguagem
- Go: `errgroup`, `lo`, `context`, `defer`, goroutine safety
- TS: async/await patterns, type narrowing, generics
- Uso de bibliotecas idiomaticas do ecossistema

#### 6. Estilo de Review
- Tom: tecnico, casual, construtivo, agressivo?
- Foco: estilo, corretude, performance, seguranca?
- Propoe codigo concreto (suggestion blocks) ou so aponta?
- Bloqueia por testes? Por estilo? Por arquitetura?

#### 7. Arquitetura
- Pensa em extensibilidade? Feature flags? Multi-tenant?
- Design patterns: nominal types, builder, strategy?
- Swagger/OpenAPI: documenta endpoints?

#### 8. Observabilidade
- Logging estruturado com contexto?
- NewRelic/tracing segments?
- Metricas de progresso em operacoes longas?

#### 9. DB Patterns
- ORM vs raw SQL? Quando cada um?
- Migrations junto com codigo?
- Indices, locks, performance awareness?

#### 10. Tendencia Geral
- Arquetipos: pragmatico, arquiteto, simplificador, incrementalista, engenheiro de qualidade
- Trade-offs que faz consistentemente
- Evolucao visivel ao longo dos PRs (melhora? estabiliza?)

### Fase 5 — Comparativo com Benchmarks

Comparar com os 5 devs de referencia do time Estrategia (todos L4, monolito Go):

```
Washington (washington-guedes)  — Arquiteto Meticuloso
  Layer: +++++ | Errors: ++++ | Tests: ++++ | Reviews: +++++ | Observability: +++++
  Marca: uma funcao por arquivo, prefixo mp, interfaces preventivas, logging impecavel
  Nivel real: L4 alto / borderline L5

Pedro Castro (pedrohlcastro)    — Operador Pragmatico Full-Stack
  Layer: +++  | Errors: +++  | Tests: ++   | Reviews: ++++  | Production: +++++
  Marca: fail-soft intencional, opera Go+JS+infra, pensa em prod antes de codigo
  Nivel real: L4 Staff — generalista senior, ve o sistema inteiro

Molina (eduardmolina)           — Simplificador Cirurgico
  Layer: ++++ | Errors: ++++ | Tests: +++  | Reviews: ++++  | Simplification: +++++
  Marca: remove abstracoes mortas, PRs cirurgicos, bounds safety em reviews
  Nivel real: L4 solido

Marquesini (joaopmarquesini)    — Incrementalista Mobile
  Layer: ++++ | Errors: ++++ | Tests: ++   | Reviews: +++   | Speed: +++++
  Marca: request struct inline, Swagger completo, iteracao rapida, BFF mobile
  Nivel real: L4

William / RafaelUnltd           — Engenheiro de Qualidade Sistematico
  Layer: +++++ | Errors: +++++ | Tests: +++++ | Reviews: ++++ | Go Idioms: +++++
  Marca: sentinel errors, named error vars em goroutines, testes de seguranca, bloqueia sem testes
  Nivel real: L4 alto — qualidade mais madura do time
```

### Fase 6 — Geracao do Relatorio

Salvar em **dois locais**:

1. **Inbox (notificacao):** `/workspace/obsidian/inbox/EVAL_<username>_<repo>.md`
2. **Vault (referencia permanente):** `/workspace/obsidian/vault/peer-reports/<org>/<Nome>.md`

O vault eh a fonte de verdade para comparacoes futuras entre devs. Usar nome real (PascalCase) como filename. Se o dev ja tem report no vault, **atualizar** o existente (nao duplicar).

Relatorios existentes no vault servem como referencia para comparacoes na matriz de competencias. Ao gerar um novo report, ler os existentes em `vault/peer-reports/` para incluir dados atualizados na matriz comparativa.

---

## Formato do Relatorio

```markdown
# Avaliacao: <username> (<repo>)

> Baseado em N PRs merged + M review comments (data)
> Nivel avaliado: LX | Arquetipos detectados: [...]

---

## Perfil: <Titulo do Arquetipo>

<Paragrafo de 3-4 linhas capturando a essencia do dev>

---

## Dimensoes

### 1. Estrutura de Codigo [+++ a +++++]
<Analise com exemplos diretos dos PRs>

### 2. Naming [+++ a +++++]
...

(repetir para todas 10 dimensoes)

---

## Matriz de Competencias

| Dimensao | <username> | Washington | Pedro | Molina | Marquesini | William |
|----------|:----------:|:----------:|:-----:|:------:|:----------:|:-------:|
| Layer    | ++++       | +++++      | +++   | ++++   | ++++       | +++++ |
| Errors   | ++++       | ++++       | +++   | ++++   | ++++       | +++++ |
| Tests    | +++        | ++++       | ++    | +++    | ++         | +++++ |
| Reviews  | +++        | +++++      | ++++  | ++++   | +++        | ++++ |
| Observ   | +++        | +++++      | +++   | ++     | +++        | ++++ |
| Simplif  | ++++       | +++        | ++++  | +++++  | +++        | +++ |
| Prod     | ++++       | ++++       | +++++ | ++++   | +++        | ++++ |
| Idioms   | ++++       | ++++       | +++   | +++    | +++        | +++++ |

## Arquetipos Detectados

<Qual(is) arquetipo(s) mais se aproxima>

## Pontos Fortes
- <com evidencia de PR especifico>

## Areas de Crescimento
- <com sugestao concreta referenciando o que os benchmarks fazem>

## Complementaridade no Time
<Como esse dev complementa ou sobrepoe com os benchmarks>

---

*Gerado em YYYY-MM-DD | Fonte: GitHub PRs + Review Comments (<repo>)*
```

---

## Notas de Calibracao

- **L3**: espera-se codigo funcional com padroes basicos. Testes podem ser ausentes. Naming pode ser inconsistente.
- **L4**: espera-se separacao de camadas, error handling adequado, testes em features novas, reviews substantivos.
- **L5/Staff**: espera-se design sistematico, sentinel errors, testes de seguranca, influencia na qualidade do time via reviews.

Se o `--level` for especificado, calibrar expectativas de acordo. Se nao, inferir do que se observa e declarar no relatorio.

---

## Execucao com Agentes

Usar 3 agentes paralelos para acelerar:

1. **Agente PR Diffs** — le todos os diffs e anota padroes por dimensao
2. **Agente Reviews** — le review comments feitos e recebidos, mapeia tom e prioridades
3. **Agente Sintese** — recebe output dos 2 anteriores, gera relatorio final

Cada agente recebe esta skill como contexto para saber as dimensoes e o formato esperado.

---

## Persistencia e Comparacoes

Todos os relatorios gerados ficam permanentemente em:
```
/workspace/obsidian/vault/peer-reports/<org>/<Nome>.md
```

Ao avaliar um dev novo, **ler todos os reports existentes** no vault para:
- Incluir na matriz comparativa
- Calibrar scores relativos (nao inflar/deflacionar)
- Identificar complementaridades no time

### Scores de Referencia (estrategiahq/monolito)

| Dev | Layer | Errors | Tests | Reviews | Observ | Simplif | Prod | Idioms | Nivel | Arquetipo |
|-----|:-----:|:------:|:-----:|:-------:|:------:|:-------:|:----:|:------:|:-----:|-----------|
| Washington | +++++ | ++++ | ++++ | +++++ | +++++ | +++ | ++++ | ++++ | L4+ | Arquiteto Meticuloso |
| Pedro Castro | +++ | +++ | ++ | ++++ | +++ | ++++ | +++++ | +++ | Staff | Operador Pragmatico |
| Molina | ++++ | ++++ | +++ | ++++ | ++ | +++++ | ++++ | +++ | L4 | Simplificador Cirurgico |
| Marquesini | ++++ | ++++ | ++ | +++ | +++ | +++ | +++ | +++ | L4 | Incrementalista Mobile |
| William | +++++ | +++++ | +++++ | ++++ | ++++ | +++ | ++++ | +++++ | L4 | Eng. Qualidade Sistematico |
| Pedrinho | ++++ | ++++ | +++ | ++++ | +++ | ++++ | ++++ | ++++ | L3+ | Arquiteto Consciente |
| Ronan | +++ | +++ | + | + | ++ | +++ | +++ | +++ | L3-L4 | Pragmatico-Incrementalista |

**Mediana do time (L4):** Layer ++++, Errors ++++, Tests +++, Reviews ++++, Observ +++, Simplif +++, Prod ++++, Idioms +++

Use esta tabela como baseline ao avaliar novos devs. Atualize-a quando novos reports forem gerados.
