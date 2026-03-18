# Mapa de Cobertura — Go Inspector

Qual inspetor cobre o quê. Usado para garantir que nada escapa entre os 5 inspetores.

---

## Matriz de Cobertura

| Aspecto | claude | docs | qa | namer | simplifier |
|---------|--------|------|----|-------|------------|
| **Correctness** | **P** | | | | |
| Lógica de negócio | **P** | | | | |
| Edge cases / nil safety | **P** | | | | |
| Race conditions | **P** | | | | |
| Error handling | **P** | | | | |
| **Performance** | **P** | | | | S |
| N+1 queries | **P** | | | | |
| Batch vs loop | **P** | | | | S |
| Cache patterns | **P** | | | | |
| **Concurrency** | **P** | | | | |
| errgroup / mutexes | **P** | | | | |
| async.Background | **P** | | | | |
| Goroutine leaks | **P** | | | | |
| **Documentação** | | **P** | | | |
| Swagger annotations | | **P** | S | | |
| Godoc exports | | **P** | | | |
| Comentários em lógica | | **P** | | | |
| Migration docs | | **P** | | | |
| **Contratos API** | | S | **P** | | |
| Request/Response structs | | | **P** | S | |
| Breaking changes | | | **P** | | |
| Validação de input | | | **P** | | |
| Status codes | | | **P** | | |
| Frontend expectations | | | **P** | | |
| **Nomenclatura** | | | | **P** | |
| Nomes de arquivos | | | | **P** | |
| Packages | | | | **P** | |
| Structs / interfaces | | | | **P** | |
| Funções / métodos | | | | **P** | |
| Variáveis / constantes | | | | **P** | |
| SQL (tabelas, colunas) | | | | **P** | |
| **Simplificação** | | | | | **P** |
| Early returns | | | | | **P** |
| Extract functions | | | | | **P** |
| Deduplicação | | | | | **P** |
| Reduce nesting | | | | | **P** |
| Dead code | | | | | **P** |
| Complexidade ciclomática | | | | | **P** |

**P** = Responsável primário
**S** = Secundário (pode reportar se encontrar, mas não é foco)

---

## Áreas de Overlap (deduplicação necessária)

1. **Swagger vs QA** — docs analisa completude do swagger, qa analisa consistência com o contrato real
2. **Naming vs QA** — namer analisa nomes dos structs, qa analisa se os nomes fazem sentido no contrato
3. **Performance vs Simplifier** — claude identifica problemas de performance, simplifier pode resolver alguns via refactor
4. **Correctness vs Simplifier** — claude encontra bugs, simplifier pode encontrar code smells que escondem bugs

## Regras de Deduplicação

- Se dois inspetores reportam o mesmo finding, manter o do inspector **primário** (P)
- Se o finding é reportado com severidades diferentes, usar a **maior** severidade
- Agrupar findings que afetam o mesmo trecho de código no consolidado
