# Catálogo de templates Mermaid (referência)

Cada ficheiro `.md` nesta pasta contém **um tipo de diagrama**, resumo de utilidade, e **um exemplo** alinhado aos projetos **Estrategia** (monolito Go, **bo-container**, **front-student**).

**Uso:** copiar o interior do bloco ` ```mermaid ` para `diagram.mmd` ou para `MERMAID_DIAGRAM_HERE` em `base.html`, no fluxo **live** descrito em `skills/webview/SKILL.md` — não substitui o relay live.

**Estilos globais** (tema, `classDef`, ícones, limites): ver `../styling-global.md`.

| Ficheiro | Tipo Mermaid | Quando escolher |
|----------|----------------|-----------------|
| [flow.md](flow.md) | `flowchart` / `graph` | Fluxos, decisões, pipelines, arquitetura lógica simples |
| [flow-subgraphs.md](flow-subgraphs.md) | `flowchart` + **vários `subgraph`** | **Segregar** apps/camadas (ex.: front-student, bo-container, monolito, fila) e **ligar** com arestas |
| [sequence.md](sequence.md) | `sequenceDiagram` | Chamadas HTTP, filas, ordem temporal entre atores |
| [state.md](state.md) | `stateDiagram-v2` | Estados de matrícula, feature flags, ciclo de vida de entidade |
| [class.md](class.md) | `classDiagram` | Modelo de domínio, relações entre entidades (UML) |
| [er.md](er.md) | `erDiagram` | Esquema relacional, cardinalidade |
| [journey.md](journey.md) | `journey` | Experiência do aluno ou do operador (sentimento + etapas) |
| [gantt.md](gantt.md) | `gantt` | Planeamento de release, dependências entre tarefas |
| [pie.md](pie.md) | `pie` | Partilha percentual (tráfego, erros por área) |
| [gitgraph.md](gitgraph.md) | `gitGraph` | Estratégia de branches, merges |
| [mindmap.md](mindmap.md) | `mindmap` | Mapa mental do ecossistema ou de um módulo |
| [timeline.md](timeline.md) | `timeline` | Marcos do produto ao longo do tempo |
| [quadrant.md](quadrant.md) | `quadrantChart` | Priorização (esforço/impacto, risco/valor) |
| [requirement.md](requirement.md) | `requirementDiagram` | Requisitos, rastreio elemento ↔ requisito |
| [sankey.md](sankey.md) | `sankey` / `sankey-beta` | Fluxo de volume (requests, eventos) entre camadas |
| [xychart.md](xychart.md) | `xychart-beta` | Séries temporais (latência, throughput) |
| [architecture.md](architecture.md) | `architecture-beta` | Serviços/recursos em grupos (cloud, ícones) |
| [block.md](block.md) | `block-beta` | Layout em grelha com controlo de colunas |
| [packet.md](packet.md) | `packet` | Estrutura de cabeçalhos binários / campos de protocolo |
| [c4-context.md](c4-context.md) | `C4Context` | Contexto: utilizadores e sistemas externos |
| [c4-container.md](c4-container.md) | `C4Container` | Apps e containers (monolito, BO, BFF, filas) |
| [c4-component.md](c4-component.md) | `C4Component` | Componentes dentro de um container |
| [c4-dynamic.md](c4-dynamic.md) | `C4Dynamic` | Sequência em estilo C4 |
| [c4-deployment.md](c4-deployment.md) | `C4Deployment` | Ambientes e nós de deploy |
| [zenuml.md](zenuml.md) | ZenUML (plugin) | Sequências estilo ZenUML (se o bundle suportar) |

Documentação oficial: [Mermaid syntax](https://mermaid.ai/open-source/syntax/syntax.html).
