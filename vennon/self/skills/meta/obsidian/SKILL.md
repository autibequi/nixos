---
name: meta/obsidian
description: "Interacao com /workspace/obsidian/ — templates, mermaid, graph, dataview. Regras do vault vivem em self/superego/ (nao aqui)."
---

# Skill: meta/obsidian

> Tudo sobre o vault em `/workspace/obsidian/`.
> **Regras de interacao:** `self/superego/README.md` (entrypoint) → `self/superego/` (detalhe)

## Sub-skills

| Sub-skill | Arquivo | Quando usar |
|---|---|---|
| **rules** | `self/superego/` | Todas as regras do sistema — ver `/superego` |
| **graph** | `graph.md` | Manter o grafo Ctrl+G: frontmatter, related, hubs, wiseman |
| **dataview** | `dataview.md` | Queries Dataview/DataviewJS no dashboard e notas |

## Templates de output

### Relatorio de Inspecao

Template: `estrategia/orquestrador/pr-inspector/templates/report.md`

```
obsidian/artefacts/inspect-pr-<N>/
├── README.md     ← indice + frontmatter
└── report.md     ← relatorio completo
```

### Card de Agente (memory.md)

```yaml
---
name: <nome>-memory
type: agent-memory
updated: YYYY-MM-DDTHH:MMZ
---
```

### Feed

Append-only em `obsidian/inbox/feed.md`:
```
[HH:MM] [nome-agente] mensagem curta
```

## Mermaid Charts

Obsidian renderiza Mermaid nativamente dentro de blocos ` ```mermaid `.
Referencia completa: https://mermaid.js.org/

### Catalogo de Tipos (todos testados no Obsidian)

#### Fluxos e Arquitetura

| Tipo | Sintaxe | Quando usar | Exemplo |
|---|---|---|---|
| **Flowchart** | `graph TB` / `graph LR` | Fluxos, decisoes, arquitetura | Ecossistema de produto, pipeline de dados |
| **Subgraphs** | `subgraph "Nome"` dentro de graph | Agrupar componentes | Frontend vs Backend vs DB |
| **Sequence** | `sequenceDiagram` | Interacoes entre sistemas | API calls, webhooks, auth flow |
| **State** | `stateDiagram-v2` | Maquinas de estado | Lead stages, order lifecycle |
| **Class** | `classDiagram` | Modelos de dados, OOP | Schema de banco simplificado |
| **ER** | `erDiagram` | Relacoes entre entidades | Schema SQL com cardinalidade |

```mermaid
graph LR
    A[Input] --> B{Decisao}
    B -->|Sim| C[Acao 1]
    B -->|Nao| D[Acao 2]
    C & D --> E[Resultado]
    style A fill:#e3f2fd
    style E fill:#c8e6c9
```

#### Graficos de Dados

| Tipo | Sintaxe | Quando usar | Exemplo |
|---|---|---|---|
| **Bar chart** | `xychart-beta` + `bar` | Rankings, comparativos, totais | Preco por bairro, custo por servico |
| **Line chart** | `xychart-beta` + `line` | Tendencias, projecoes, series | MRR ao longo do tempo, 3 cenarios |
| **Multi-line** | `xychart-beta` + multiplos `line` | Comparar cenarios | Otimista vs realista vs pessimista |
| **Bar + Line** | `xychart-beta` + `bar` + `line` | Valores absolutos + tendencia | Volume + taxa de conversao |
| **Pie** | `pie` | Distribuicao proporcional | Market share, alocacao de budget |

```mermaid
xychart-beta
    title "Exemplo: MRR por Mes (R$)"
    x-axis ["Jan","Fev","Mar","Abr","Mai","Jun"]
    y-axis "R$" 0 --> 5000
    line "Cenario A" [0, 500, 1200, 2000, 3000, 4500]
    line "Cenario B" [0, 200, 400, 800, 1200, 1800]
    bar [100, 300, 600, 1000, 1500, 2500]
```

```mermaid
pie title Distribuicao de Budget
    "Ads" : 40
    "Conteudo" : 25
    "Infra" : 15
    "Legal" : 10
    "Outros" : 10
```

#### Posicionamento e Analise

| Tipo | Sintaxe | Quando usar | Exemplo |
|---|---|---|---|
| **Quadrant** | `quadrantChart` | Posicionamento 2D, prioridade | Impacto×Esforco, Preco×Completude, Risco×Probabilidade |
| **Mindmap** | `mindmap` | Brainstorm, taxonomia, visao geral | SWOT expandido, features do produto |

```mermaid
quadrantChart
    title Exemplo: Impacto vs Esforco
    x-axis "Facil" --> "Dificil"
    y-axis "Baixo Impacto" --> "Alto Impacto"
    "Quick Win A": [0.2, 0.8]
    "Projeto Grande": [0.8, 0.9]
    "Nice to Have": [0.3, 0.2]
    "Armadilha": [0.9, 0.1]
```

```mermaid
mindmap
  root((Projeto))
    Mercado
      Tamanho
      Concorrencia
      Tendencias
    Produto
      MVP
      Features
      Tech Stack
    Financeiro
      Receita
      Custos
      Projecoes
```

#### Timeline e Planejamento

| Tipo | Sintaxe | Quando usar | Exemplo |
|---|---|---|---|
| **Gantt** | `gantt` | Cronograma, roadmap, sprints | Roadmap 12 meses, GTM 8 semanas |
| **Timeline** | `timeline` | Eventos historicos, marcos | Historia do projeto, marcos de lancamento |

```mermaid
gantt
    title Exemplo: Sprint 2 semanas
    dateFormat YYYY-MM-DD
    section Backend
    Auth JWT          :a1, 2026-04-01, 3d
    Pagamento Asaas   :a2, after a1, 2d
    section Frontend
    Dashboard         :b1, 2026-04-01, 4d
    Upload fotos      :b2, after b1, 2d
    section Deploy
    Producao          :c1, after a2, 1d
```

#### Experiencia do Usuario

| Tipo | Sintaxe | Quando usar | Exemplo |
|---|---|---|---|
| **Journey** | `journey` | Jornada do usuario, satisfacao por etapa | Onboarding, funil de conversao |

```mermaid
journey
    title Exemplo: Jornada do Cliente
    section Descoberta
      Encontra o site: 3: Cliente
      Le sobre o produto: 4: Cliente
    section Trial
      Cria conta gratis: 5: Cliente
      Usa feature principal: 4: Cliente
    section Conversao
      Trial expira: 2: Cliente
      Paga subscription: 4: Cliente
```

### Estilizacao

```mermaid
graph LR
    A[Normal] --> B[Verde]
    B --> C[Vermelho]
    C --> D[Amarelo]
    D --> E[Azul com borda]

    style A fill:#ffffff
    style B fill:#c8e6c9
    style C fill:#ffcdd2
    style D fill:#fff9c4
    style E fill:#bbdefb,stroke:#1565c0,stroke-width:2px
```

Cores uteis (Material Design):
- Verde (sucesso): `#c8e6c9`
- Vermelho (erro/critico): `#ffcdd2`
- Amarelo (atencao): `#fff9c4`
- Azul (info): `#bbdefb`, `#e3f2fd`
- Roxo (futuro): `#d1c4e9`
- Laranja (warning): `#ffe0b2`

### Boas Praticas

- **1 grafico por conceito** — nao sobrecarregar
- **Titulo sempre** — `title "..."` em xychart, titulo no texto em outros
- **Callout interpretativo** junto ao grafico (o que o leitor deve concluir)
- **Labels curtos** — usar `<br>` para quebrar linha dentro de nodes
- **Subgraphs** para agrupar (melhora legibilidade)
- **Cores** para destacar (verde=bom, vermelho=ruim, amarelo=atencao)
- **Links tracejados** `-.->` para conexoes futuras/opcionais
- **TB** (top-bottom) para hierarquias, **LR** (left-right) para fluxos
- **Combinar tipos** — journey para UX, gantt para timeline, xychart para dados, quadrant para posicionamento
- **Dark mode**: `%%{init: {'theme': 'dark'}}%%` na primeira linha do bloco

### Quando usar cada tipo (decisao rapida)

```
Preciso mostrar...
├── Fluxo/processo/decisao → graph TB/LR
├── Dados numericos ao longo do tempo → xychart-beta line
├── Comparacao de valores → xychart-beta bar
├── Distribuicao/proporcao → pie
├── Posicionamento 2D (X vs Y) → quadrantChart
├── Cronograma/roadmap → gantt
├── Jornada do usuario → journey
├── Brainstorm/taxonomia → mindmap
├── Relacoes entre entidades → erDiagram
├── Interacao entre sistemas → sequenceDiagram
└── Estados e transicoes → stateDiagram-v2
```

## Convencoes Obsidian

- Frontmatter YAML sempre no topo
- Datas em ISO 8601 UTC
- Links internos: `[[nome-do-arquivo]]`
- Tags: `#tag` no body, NAO no frontmatter
- `related:` no frontmatter para edges no graph
- Callouts: `[!example]+` leitura, `[!tip]+` insight, `[!warning]+` gaps
