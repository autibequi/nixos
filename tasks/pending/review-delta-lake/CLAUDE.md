# Code Review — add-use-delta-lake

## Contexto
Este é código de OUTRA pessoa. O objetivo é fazer code review formal — encontrar bugs, problemas de arquitetura e sugerir melhorias.

- **Repositório:** `/workspace/projetos/claudio/monolito/`
- **Branch:** `add-use-delta-lake`

## Passos

### 1. Setup (máx 1 min)
```bash
cd /workspace/projetos/claudio/monolito
git fetch origin
git checkout add-use-delta-lake
git pull origin add-use-delta-lake
```

### 2. Entender o diff (máx 3 min)
```bash
git diff origin/main...HEAD --stat
git log origin/main...HEAD --oneline
```
- Ler TODOS os arquivos alterados
- Entender: o que é Delta Lake, por que está sendo adicionado, qual o escopo da mudança

### 3. Code Review (máx 4 min)
Avaliar com olho de reviewer:

**Correção:**
- Lógica está correta?
- Edge cases tratados?
- Erros propagados corretamente?

**Arquitetura:**
- Segue os padrões do monolito? (handler → service → repository)
- DI está wired corretamente?
- Não quebra responsabilidade das camadas?

**Performance:**
- Queries eficientes?
- Sem N+1?
- Cache quando necessário?

**Segurança:**
- SQL injection?
- Input validation?
- Auth/authz corretos?

**Manutenibilidade:**
- Código legível?
- Nomes fazem sentido?
- Testes existem e cobrem o essencial?

### 4. Gerar relatório (máx 2 min)
Escrever `<diretório de contexto>/contexto.md`:

```
# Code Review — add-use-delta-lake
**Data:** <timestamp>
**Branch:** add-use-delta-lake
**Autor:** <pegar do git log>

## Resumo da mudança
<o que está sendo adicionado/mudado e por quê>

## Arquivos alterados
<lista com breve descrição de cada>

## Issues encontradas

### Críticas (bloqueia merge)
| # | Arquivo:Linha | Descrição |
|---|---------------|-----------|

### Importantes (deveria corrigir)
| # | Arquivo:Linha | Descrição |
|---|---------------|-----------|

### Sugestões (nice to have)
| # | Arquivo:Linha | Descrição |
|---|---------------|-----------|

## Pontos positivos
<o que está bem feito>

## Veredicto
✅ Approve | ⚠️ Request changes | ❌ Reject
```

## Regras
- NÃO modifique nenhum arquivo — apenas leia e analise
- Seja justo e construtivo — é código de colega
- Priorize: bugs > arquitetura > performance > estilo
- Se não conseguir fazer checkout da branch, documente o erro e analise o que conseguir
