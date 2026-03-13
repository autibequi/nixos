# Review — cached-ldi-toc (meu código)

## Contexto
Este é código do PRÓPRIO usuário. O objetivo é validar se a implementação faz o que deveria.

- **Repositório:** `/workspace/projetos/claudio/monolito/`
- **Branch:** `FUK2-11746-vibed/cached-ldi-toc`
- **PR:** https://github.com/estrategiahq/monolito/pull/4436

## Passos

### 1. Setup (máx 1 min)
```bash
cd /workspace/projetos/claudio/monolito
git fetch origin
git checkout FUK2-11746-vibed/cached-ldi-toc
git pull origin FUK2-11746-vibed/cached-ldi-toc
```

### 2. Entender o diff (máx 3 min)
```bash
git diff origin/main...HEAD --stat
git log origin/main...HEAD --oneline
```
- Ler TODOS os arquivos alterados
- Entender: o que foi adicionado, modificado, removido

### 3. Analisar a lógica (máx 4 min)
Para cada arquivo alterado:
- A lógica de cache está correta? (invalidação, TTL, race conditions?)
- O TOC (Table of Contents) está sendo montado corretamente?
- Os endpoints retornam os dados esperados?
- Queries SQL estão otimizadas? (N+1? índices?)
- Tratamento de erros está adequado?
- Segue os padrões do monolito? (layers: handler → service → repository)

### 4. Gerar relatório (máx 2 min)
Escrever `<diretório de contexto>/contexto.md`:

```
# Review — cached-ldi-toc
**Data:** <timestamp>
**Branch:** FUK2-11746-vibed/cached-ldi-toc
**PR:** #4436

## Resumo do que o código faz
<2-3 frases>

## Arquivos alterados
<lista com breve descrição de cada>

## Validação: faz o que deveria?
- [ ] Cache implementado corretamente
- [ ] TOC montado com dados corretos
- [ ] Invalidação de cache funciona
- [ ] Sem race conditions
- [ ] Queries otimizadas
- [ ] Testes cobrem os cenários

## Problemas encontrados
| # | Severidade | Arquivo:Linha | Descrição |
|---|-----------|---------------|-----------|

## Sugestões de melhoria
<lista>

## Veredicto
✅ Pronto pra merge | ⚠️ Ajustes necessários | ❌ Repensar abordagem
```

## Regras
- NÃO modifique nenhum arquivo — apenas leia e analise
- Seja crítico mas construtivo — é o código do próprio dev
- Foque em bugs reais e problemas de lógica, não em estilo
