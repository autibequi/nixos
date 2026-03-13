# Pesquisar Controle de Tokens

## Objetivo
Pesquisar e documentar estratégias de controle de consumo de tokens da API Anthropic (Claude) para otimizar custo e uso no setup autônomo do Claudinho.

## O que pesquisar

### 1. Mecanismos de controle
- `max_tokens` — como configurar limites por request
- `--max-turns` — limitar turnos em modo agêntico
- Token budgets — existe forma de limitar gasto total por sessão?
- Rate limits — como funciona por tier, como monitorar headroom
- Caching de prompts — prompt caching reduz custo? Como ativar?

### 2. Otimizações práticas pro Claudinho
- O prompt do runner (`clau-runner.sh`) pode ser otimizado pra gastar menos tokens?
- Tasks com CLAUDE.md muito grande: vale comprimir instruções?
- Subagentes herdam contexto? Se sim, como minimizar duplicação?
- `--permission-mode bypassPermissions` tem impacto em tokens?

### 3. Monitoramento
- Admin API — dá pra ver uso por API key?
- Headers de resposta — quais retornam info de tokens usados?
- Como implementar tracking automático no runner

### 4. Melhores práticas
- O que a documentação Anthropic recomenda pra reduzir custo
- Patterns comuns: resumir contexto, truncar histórico, system prompt enxuto
- Extended thinking — quando vale a pena (mais tokens mas melhor resultado)?

## Entregável
Escrever `<diretório de contexto>/contexto.md`:

```
# Pesquisa — Controle de Tokens
**Data:** <timestamp>

## Findings
<resultado da pesquisa organizado por tópico>

## Recomendações pro Claudinho
| # | Ação | Impacto estimado | Esforço |
|---|------|-----------------|---------|

## Próximos passos
<o que implementar e em que ordem>
```

## Regras
- Task ONE-SHOT — pesquisa e documenta, depois vai pra done/
- Pode usar WebSearch e WebFetch pra consultar docs da Anthropic
- NÃO modifique código — apenas pesquise e documente
- Foque em ações práticas, não teoria genérica
