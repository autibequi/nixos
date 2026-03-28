# Mapa de Cobertura — Go Inspector

Qual inspetor cobre o quê. Usado para garantir que nada escapa entre os 7 inspetores.

---

## Matriz de Cobertura

| Aspecto | architect | claude | docs | qa | namer | coverage | simplifier |
|---------|-----------|--------|------|----|-------|----------|------------|
| **Visão Geral e Contexto** | **P** | | | | | | |
| Motivação do PR | **P** | | | | | | |
| Arquitetura geral | **P** | | | | | | |
| Fluxo principal | **P** | | | | S | | |
| Tópicos de discussão | **P** | | | | | | |
| **Schema e Layers** | **P** | | | | | | |
| Migrations (goose Up/Down) | **P** | | | | | | |
| Entities (GORM tags, TableName) | **P** | | | | | | |
| Interfaces (contratos, breaking changes) | **P** | | | **S** | | | |
| Repos (repoImpl, Container) | **P** | | | | | | |
| Config/Infra (toggler, k8s) | **P** | | | | | | |
| **Knowledge check de domínio** | **P** | | | | | | |
| Patterns pagamento_professores | **P** | | | | | | |
| Verticals, AppServices, JSONB | **P** | **S** | | | | | |
| **Correctness** | | **P** | | | | | |
| Lógica de negócio | **S** | **P** | | | | | |
| Edge cases / nil safety | | **P** | | | | | |
| Race conditions | | **P** | | | | | |
| Error handling | | **P** | | | | | |
| **Performance** | | **P** | | | | | S |
| N+1 queries | | **P** | | | | | |
| Batch vs loop | | **P** | | | | | S |
| Cache patterns | | **P** | | | | | |
| **Concurrency** | | **P** | | | | | |
| errgroup / mutexes | | **P** | | | | | |
| async.Background | | **P** | | | | | |
| Goroutine leaks | | **P** | | | | | |
| **Observabilidade** | | **P** | | | | | |
| newrelic segments | | **P** | | | | | |
| elogger correto | | **P** | | | | | |
| **Documentação** | | | **P** | | | | |
| Swagger annotations | | | **P** | S | | | |
| Godoc exports | | | **P** | | | | |
| Comentários em lógica | | | **P** | | | | |
| Migration docs | | | **P** | | | | |
| **Contratos API** | | | S | **P** | | | |
| Request/Response structs | | | | **P** | S | | |
| Breaking changes | **S** | | | **P** | | | |
| Validação de input | | | | **P** | | | |
| Status codes | | | | **P** | | | |
| Frontend expectations | | | | **P** | | | |
| **Nomenclatura** | | | | | **P** | | |
| Nomes de arquivos | | | | | **P** | | |
| Packages | | | | | **P** | | |
| Structs / interfaces | | | | | **P** | | |
| Funções / métodos | | | | | **P** | | |
| Variáveis / constantes | | | | | **P** | | |
| SQL (tabelas, colunas) | **S** | | | | **P** | | |
| **Cobertura de Testes** | | | | | | **P** | |
| Mapeamento de fluxos | | | | | | **P** | |
| Happy path coberto | | | | | | **P** | |
| Error paths cobertos | | | | | | **P** | |
| Edge cases cobertos | | | | | | **P** | |
| Testes de integração | | | | S | | **P** | |
| Gaps críticos | | | | | | **P** | |
| **Simplificação** | | | | | | | **P** |
| Early returns | | | | | | | **P** |
| Extract functions | | | | | | | **P** |
| Deduplicação | | | | | | | **P** |
| Reduce nesting | | | | | | | **P** |
| Dead code | | | | | | | **P** |
| Complexidade ciclomática | | | | | | | **P** |

**P** = Responsável primário
**S** = Secundário (pode reportar se encontrar, mas não é foco)

---

## Áreas de Overlap (deduplicação necessária)

1. **Architect vs Claude** — architect analisa design da entity/interface, claude analisa correctness do uso delas
2. **Architect vs QA** — architect verifica breaking changes estruturais, qa verifica impacto no contrato de API
3. **Coverage vs QA** — qa verifica se há testes de contrato; coverage verifica se há testes de lógica de negócio
4. **Swagger vs QA** — docs analisa completude do swagger, qa analisa consistência com o contrato real
5. **Naming vs QA** — namer analisa nomes dos structs, qa analisa se os nomes fazem sentido no contrato
6. **Performance vs Simplifier** — claude identifica problemas de performance, simplifier pode resolver alguns via refactor

## Regras de Deduplicação

- Se dois inspetores reportam o mesmo finding, manter o do inspector **primário** (P)
- Se o finding é reportado com severidades diferentes, usar a **maior** severidade
- Agrupar findings que afetam o mesmo trecho de código no consolidado
