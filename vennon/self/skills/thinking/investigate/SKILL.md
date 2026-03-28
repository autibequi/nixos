---
name: thinking/investigate
description: Coleta de dados antes de pensar — levantar logs, código, relatos, prints, histórico git. Executada no início de qualquer pipeline thinking. Não forma hipótese, só coleta.
---

# thinking/investigate — Coleta de Dados

> Antes de pensar, coletar. A tentação de já concluir nessa fase é a maior fonte de erro.
> Regra de ouro: **nenhuma hipótese aqui**. Só evidências brutas.

---

## Quando executar

Sempre como **primeira fase** do pipeline thinking — antes de qualquer análise ou hipótese.

---

## Contexto da plataforma — carregar antes de investigar

Se o problema envolver qualquer repo da Estrategia, carregar `estrategia/platform-context` para entender:

| Repo | Stack | Responsabilidade |
|---|---|---|
| **monolito** | Go, GORM, zerolog | API REST — handlers → services → repositories → workers |
| **bo-container** | Vue 2, Quasar | Interface administrativa (backend office) |
| **front-student** | Nuxt 2, SSR | Portal do aluno |

Paths dos repos:
```
/workspace/home/                         ← projeto ativo montado aqui
/home/claude/projects/estrategia/
├── monolito/
├── bo-container/
└── front-student/
```

URLs sandbox local:
```
http://api.local.estrategia-sandbox.com.br      ← monolito
http://admin.local.estrategia-sandbox.com.br    ← bo-container
http://local.estrategia-sandbox.com.br          ← front-student
```

---

## Árvore de localização — onde está o problema?

Antes de ir fundo, identificar a camada. Usar como mapa:

```
Problema
├── monolito (Go)
│   ├── internal/handlers/        ← entrada HTTP, validação de request
│   ├── internal/services/        ← lógica de negócio
│   ├── internal/repositories/    ← acesso ao banco (GORM)
│   ├── internal/workers/         ← jobs assíncronos
│   ├── migrations/               ← schema do banco
│   └── /workspace/logs/docker/monolito/   ← logs runtime
│
├── bo-container (Vue 2 + Quasar)
│   ├── src/pages/                ← telas
│   ├── src/components/           ← componentes
│   ├── src/services/             ← chamadas à API
│   ├── src/store/                ← estado (Vuex)
│   └── /workspace/logs/docker/bo-container/
│
├── front-student (Nuxt 2)
│   ├── pages/                    ← rotas SSR
│   ├── components/               ← componentes
│   ├── services/                 ← chamadas à API
│   ├── store/                    ← estado (Vuex)
│   └── /workspace/logs/docker/front-student/
│
├── infra / leech
│   ├── /workspace/self/          ← skills, hooks, agentes
│   └── /workspace/logs/          ← todos os logs centralizados
│
└── host / NixOS
    ├── /workspace/host/          ← config NixOS (se host_attached=1)
    └── /workspace/logs/host/     ← journal, var-log
```

Escolher 1 camada como mais provável e ir fundo — não investigar tudo em paralelo.

---

## O que levantar

### Logs da aplicação
```
Verificar proativamente /workspace/logs/<nome-da-aplicacao>/
- Ler últimas 100-200 linhas sem perguntar ao user
- Registrar: mensagem exata, timestamp, frequência, contexto anterior ao erro
```

### Código relevante
- Arquivos mencionados no stack trace ou relato
- Handler/service/repo da feature em questão
- Interfaces e contratos envolvidos

### Relato do usuário / Jira
- Descrição exata do problema (sem parafrasear)
- Passos para reproduzir (se existirem)
- Comportamento esperado vs obtido
- Se card Jira: invocar `estrategia/jira` para extrair todos os campos

### Histórico recente
```bash
git log --oneline -20          # mudanças recentes
git diff HEAD~1                # o que mudou no último commit
git blame <arquivo>            # quem tocou qual linha
```

### Prints / screenshots
Se fornecidos pelo usuário: analisar visualmente antes de continuar.

### Estado externo (se acessível)
- Grafana (`estrategia/grafana`): métricas de latência, taxa de erro, throughput
- OpenSearch (`estrategia/opensearch`): busca por trace_id ou mensagem exata em logs centralizados

---

## Output da fase

Ao final da coleta, produzir um **sumário estruturado**:

```
## Dados coletados

### Logs
- [mensagem exata]
- [timestamp / frequência]
- [contexto anterior]

### Código
- [arquivo:linha] — [o que faz]
- [arquivo:linha] — [o que faz]

### Relato
- [descrição exata do usuário]
- [repro steps, se existirem]

### Histórico
- [último commit relevante]
- [mudança recente relacionada]

### Lacunas
- [o que não foi possível coletar e por quê]
```

Passar esse sumário para `thinking/SKILL.md` continuar o pipeline.

---

## Regras

1. **Não concluir nada** — coletar, não interpretar
2. **Ser exaustivo** — melhor coletar a mais do que deixar passar uma evidência
3. **Registrar lacunas** — se algo não foi encontrado, anotar explicitamente
4. **Logs são proativos** — nunca perguntar "quer que eu veja os logs?" — simplesmente ver
