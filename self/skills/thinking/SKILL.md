---
name: thinking
description: Skill de destrinchamento de problema — ler card Jira, investigar codebase, mapear camadas, quebrar em tasks atomicas e apresentar visualmente para validacao antes de qualquer implementacao. Usa meta:art para o output. Sub-skill: thinking/refine.
---

# thinking — Destrinchar Problema Antes de Implementar

> Nunca sair fazendo. Entender primeiro. Apresentar. Validar. Depois implementar.

Skill composta para resolver problemas de forma estruturada. O output e sempre visual (via `meta:art`) e precisa de validacao do usuario antes de qualquer codigo ser escrito.

## Sub-skills

| Arquivo | Quando usar |
|---|---|
| `refine` | Quebrar feature/spec em tasks atomicas ordenadas por camada |

---

## Fluxo principal

```
Problema/Card recebido
        │
        ▼
[1] Ler e entender       — Jira card, spec, descricao do usuario
        │
        ▼
[2] Investigar           — codebase, padroes existentes, camadas
        │
        ▼
[3] Mapear               — dependencias, riscos, decisoes em aberto
        │
        ▼
[4] Apresentar           — visual via meta:art (ASCII ou Chrome)
        │
        ▼
[5] Validar              — usuario aprova, ajusta, ou rejeita
        │
        ▼
[6] Refinar tasks        — invocar thinking/refine → backlog atomico
        │
        ▼
[7] Implementar          — so apos aprovacao explicita
```

---

## Passo 1 — Ler o problema

Se vier como card Jira: invocar `estrategia/jira` para extrair todos os campos.

Se vier como descricao livre: extrair:
- **O que** deve ser feito (funcionalidade)
- **Por que** (motivacao/contexto de negocio)
- **Criterios de aceite** (como saber que esta pronto)
- **O que esta fora do escopo** (explicitamente)

---

## Passo 2 — Investigar o codebase

Nao planejar sem investigar. Busca em 3 ondas:

**Onda 1 — Mapa geral:**
```bash
# Estrutura de pastas
# Arquivos de entrada (main, app, schema, rotas)
# Dependencias declaradas (go.mod, package.json, pubspec.yaml)
```

**Onda 2 — Padroes existentes:**
- 1 entidade/struct existente → naming e estrutura
- 1 repositorio/service existente → padrao de acesso
- 1 handler/component existente → padrao de UI ou API

**Onda 3 — Pontos de extensao:**
- Onde registrar o novo componente (DI container, main, router)
- Existe algo similar ja implementado?
- Quais interfaces precisam mudar?

---

## Passo 3 — Mapear dependencias e riscos

Identificar antes de criar tasks:

| Item | Perguntas |
|---|---|
| **Camadas** | Quantas camadas tocam? Qual a ordem de dependencia? |
| **Riscos** | O que pode dar errado? Quais decisoes tecnicas em aberto? |
| **Ambiguidades** | O que a spec nao define? Precisa de input do usuario agora? |
| **Impacto** | O que pode quebrar? Tem testes existentes? |

---

## Passo 4 — Apresentar visualmente via meta:art

**Sempre apresentar antes de qualquer implementacao.**

Ler `meta:art` e escolher o formato:

```
Output cabe no terminal (< 80 linhas)?
    └─ ASCII: fluxo, mapa de caixas, kanban compacto, tabela
Output grande / interativo?
    └─ Chrome relay: Mermaid flowchart, arvore interativa
```

### Formatos recomendados por tipo de problema

| Tipo de problema | Formato meta:art |
|---|---|
| Feature nova com multiplas camadas | Diagrama de camadas (caixas IN/OUT) + kanban de tasks |
| Bug / investigacao | Fluxo de handler + tabela de hipoteses |
| Refactor | Tabela antes/depois + mapa de dependencias |
| Feature cross-repo | Mermaid flowchart no Chrome (sequencia entre servicos) |

### O que o output deve conter

1. **Resumo do entendimento** — o que voce entendeu do problema (1 paragrafo)
2. **Mapa de impacto** — camadas/arquivos afetados (ASCII ou Mermaid)
3. **Decisoes em aberto** — o que precisa de validacao antes de prosseguir
4. **Proposta de tasks** — lista numerada com estimativa de esforco
5. **Riscos identificados** — o que pode complicar

---

## Passo 5 — Validar com o usuario

Apos apresentar, parar e esperar resposta explicita.

Perguntar:
- "Esse entendimento esta correto?"
- "Tem algo fora do escopo que incluí por engano?"
- "As decisoes em aberto — voce ja tem preferencia?"

**Nao avancar sem resposta.**

---

## Passo 6 — Refinar tasks (invocar thinking/refine)

Apos validacao, invocar `thinking/refine` para:
- Quebrar em tasks atomicas (cada uma max ~30min)
- Ordenar respeitando camadas de dependencia
- Formatar backlog com T01, T02... + tabela de progresso
- Identificar tasks paralelas

---

## Passo 7 — Implementar

So apos backlog aprovado. Seguir a ordem das tasks. Nao pular camadas.

---

## Gatilhos de uso

| Situacao | Acao |
|---|---|
| Card Jira recebido para implementar | **Obrigatorio** — rodar thinking completo |
| Feature com mais de 2 arquivos | **Obrigatorio** |
| Pedido vago ("faz um sistema de X") | **Obrigatorio** — clarificar antes de refinar |
| Bug complexo sem causa clara | **Obrigatorio** — rodar modo debug (ver secao abaixo) |
| Log ou stack trace recebido | **Obrigatorio** — rodar modo debug |
| Duvida sobre onde esta o problema | **Obrigatorio** — localizar camada antes de investigar |
| Hotfix urgente (<1 arquivo, causa clara) | Dispensavel |

> **Regra:** sempre que houver log, erro ou duvida sobre onde esta o problema — acionar thinking antes de qualquer acao.

---

## Modo Debug — Quando ha log ou duvida

Fluxo especifico para debugging. Complementa `code/debug` adicionando localizacao de camada e validacao de logs.

```
Log / erro / duvida recebido
        │
        ▼
[D1] Localizar          — em qual camada/ambiente esta o problema?
        │
        ▼
[D2] Verificar acesso   — ha logs disponiveis? onde?
        │
        ▼
[D3] Ler os logs        — extrair evidencias concretas
        │
        ▼
[D4] Ler o codigo       — estado atual do codigo que quebrou
        │
        ▼
[D5] Validar            — o log corresponde ao codigo lido?
        │
        ▼
[D6] Hipoteses          — mapear causas prováveis com evidencia
        │
        ▼
[D7] Apresentar         — visual via meta:art + validar com usuario
```

### D1 — Localizar: onde esta o problema?

Antes de investigar, determinar a camada:

| Camada | Indicios | Onde olhar |
|---|---|---|
| **Host / NixOS** | Erro em servico do sistema, config nix, daemon | `/workspace/host`, `~/nixos`, logs do journal |
| **Zion CLI / container** | Erro em skill, hook, boot, agente | `/workspace/self/`, logs do container |
| **Self skills** | Skill nao executa, output errado | `/workspace/self/skills/`, `.claude/settings.json` |
| **Projeto em mnt/** | Erro de aplicacao, teste falhando, build quebrado | `/workspace/mnt/`, logs do projeto |

Nao investigar todas as camadas — escolher a mais provavel e ir fundo.

### D2 — Verificar acesso a logs

```bash
# Container / Docker
docker logs <container> --tail 100
ls /workspace/logs/docker/

# Aplicacao Go (monolito)
tail -f /workspace/logs/docker/<servico>.log

# Servicos do host (read-only)
ls /workspace/logs/host/var-log/
ls /workspace/logs/host/journal/

# Docker Compose
docker compose logs --tail 50 <servico>
```

Se nao ha logs: pedir ao usuario antes de avancar.

### D3 — Ler os logs

Extrair do log:
- **Mensagem de erro exata** — copiar literal, nao parafrear
- **Timestamp** — quando ocorreu, com que frequencia
- **Stack trace / goroutine** — qual funcao / linha
- **Contexto** — linhas anteriores ao erro (o que aconteceu antes)

### D4 — Ler o codigo que quebrou

Com a linha/funcao identificada no log:
- Ler o arquivo e a funcao referenciada
- Verificar o estado atual (pode ter mudado desde o log)
- `git log --oneline -10` — houve mudanca recente?

### D5 — Validar correspondencia log x codigo

- O erro no log faz sentido dado o codigo atual?
- O codigo mudou desde o log? (novo deploy pode ter corrigido ou piorado)
- A linha apontada no stack trace existe e tem a logica esperada?

Se log e codigo divergem (codigo mudou): verificar se o problema ainda existe antes de propor qualquer fix.

---

## Skills e ferramentas para investigacao

| Ferramenta / Skill | Quando usar |
|---|---|
| `code/debug` | Debugging sistematico (4 fases: reproduzir, hipoteses, isolar, verificar) |
| `estrategia/grafana` | Metricas, latencia, erros em producao/staging |
| `estrategia/opensearch` | Busca em logs centralizados por trace_id ou mensagem de erro |
| `estrategia/jira` | Ler card, historico, comentarios, repro steps reportados |
| `estrategia/glance` | Overview rapido do estado dos repos e servicos |
| `code/analysis` | Entender fluxo de codigo, dependencias entre camadas |
| `code/inspect` | Inspecionar arquivo/funcao especifica em detalhe |
| `thinking/refine` | Quebrar investigacao em tasks atomicas apos entender o problema |

**Comandos uteis:**
```bash
git log --oneline -20              # mudancas recentes
git diff HEAD~1                    # o que mudou no ultimo commit
git blame <arquivo>                # quem tocou qual linha quando
docker logs <container> --tail 100 # logs do container
grep -r "mensagem exata" /workspace/mnt/  # buscar ocorrencia no codigo
```

---

## Anti-patterns

| Errado | Certo |
|---|---|
| Sair implementando sem ler o card completo | Ler todos os campos Jira, inclusive comentarios |
| Apresentar so texto, sem visual | Sempre usar meta:art — o visual facilita a validacao |
| Pedir validacao e avancar sem resposta | Parar. Esperar. Nao presumir aprovacao |
| Refinar sem investigar o codebase | Onda 1-2-3 primeiro, plano depois |
| Criar tasks grandes ("implementar o modulo X") | Cada task = 1 responsabilidade, resultado verificavel |
