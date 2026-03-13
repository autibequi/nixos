# usage-tracker — Memória

## Resumo
Task recorrente para rastrear uso de tokens/custos da API Anthropic. Atualmente sem API keys configuradas — opera em modo degradado, analisando apenas dados de execução locais (2026-03.jsonl).

O script `api-usage.sh` não existe ainda. Precisa ser criado para integrar com Admin API.

## Histórico de execuções

### 2026-03-13T11:33:45Z
- **O que fiz:** Verificou que `api-usage.sh` não existe e nem ANTHROPIC_API_KEY nem ANTHROPIC_ADMIN_KEY estão configuradas. Analisou dados do `.ephemeral/usage/2026-03.jsonl` (14 registros de tasks autônomas).
- **O que aprendi:** 57% das tasks autônomas estão falhando com timeout (fail:124). Sem Admin Key, não é possível obter dados reais de custo da API Anthropic. As execuções anteriores desta task também falharam por timeout — provavelmente tentavam fazer algo pesado.
- **Decisões:** Mantiver task simples — só analisa dados locais disponíveis e documenta o estado sem keys.
- **Próximos passos:** Criar `api-usage.sh` quando Admin Key estiver disponível. Considerar reduzir escopo das tasks que estão dando timeout.

### 2026-03-13T11:39:25Z
- **O que fiz:** Analisou 15 registros em 2026-03.jsonl. Padrão claro: tasks simples (<200s) = 100% OK; tasks complexas (600s) = 100% timeout.
- **O que aprendi:** Timeout rate caiu de 57% → 53% com nova run ok do usage-tracker. Padrão consistente: tasks recorrentes pesadas (doctor, parceiro, avaliar-m5) nunca completam. Paralelismo (teste-paralelo-*) também 100% timeout.
- **Decisões:** Task está funcional no modo degradado. Foco em ser rápida e não travar.
- **Próximos passos:** Sem mudança — aguardar Admin Key para funcionalidade real. Alertar que tasks recorrentes pesadas precisam ser revisadas.

### 2026-03-13T11:40:53Z
- **O que fiz:** Analisou 16 registros em 2026-03.jsonl. Atualizou contexto com novo snapshot.
- **O que aprendi:** Timeout rate subiu ligeiramente de 53% → 56%. melhorar-automacoes agora com 50% OK (antes 100%). usage-tracker estável com 2/3 runs OK e avg caindo de 330s → 240s.
- **Decisões:** Task continua no modo degradado eficiente. Nada a mudar.
- **Próximos passos:** Sem mudança. Tasks pesadas (doctor, parceiro, avaliar-m5) permanecem problemáticas.
