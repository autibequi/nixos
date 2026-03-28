---
name: coruja/ecosystem-map
description: "Mapa completo de todos os repositorios da Estrategia Educacional — 19 projetos com stack, proposito, responsabilidade e paths. Usar ao refinar cards Jira que envolvam repos fora do trio principal (monolito/bo/front-student), ou quando a pista do bug nao se encaixa nos 3 repos conhecidos."
---

# Estrategia — Mapa do Ecossistema Completo

Base path: `/home/claude/projects/estrategia/`
GitHub org: `estrategiahq`

---

## Categoria: Core da Plataforma (os 3 repos principais)

| Repo | Stack | Proposito |
|---|---|---|
| **monolito** | Go 1.24, GORM, Echo, PostgreSQL, Redis | Backend principal multi-app. Contem todos os dominios de negocio: LDI, questoes, cast, materiais, ecommerce, social, ranking, cursos, coaching, monitorias, trilhas, redacoes, etc. |
| **bo-container** | Vue 2, Options API, Quasar, hash routing | Interface administrativa (backoffice). Usada por operadores, professores, moderadores e equipe interna. |
| **front-student** | Nuxt 2, Options API, SSR, Vue 2 | Portal do aluno. Area logada onde o aluno acessa cursos, LDI, questoes, simulados, streaming. |

### Monolito — Sub-apps relevantes

```
apps/
  bff/           — BFF para front-student e bo-container (web)
  bff_mobile/    — BFF para o app mobile (Flutter)
  bo/            — Handlers de backoffice
  ldi/           — Dominio LDI (cursos, capitulos, itens, blocos, videos)
  questoes/      — Dominio de questoes e cadernos
  cast/          — Dominio de podcasts/trilhas de audio
  materiais/     — Dominio de materiais/PDFs/videos (My Documents)
  monitorias/    — Dominio de monitorias ao vivo
  cursos/        — Dominio de cursos tradicionais
  coaching/      — Dominio de coaching personalizado
  trilhas_estrategicas/ — Trilhas de estudo personalizadas
  ranking/       — Ranking de alunos
  social/        — Comentarios, forum, interacoes sociais
  ecommerce/     — Produtos, pedidos, cupons (tambem tem repo proprio)
  redacoes/      — Dominio de redacoes
  discursivas/   — Questoes discursivas
  performance/   — Metricas de desempenho do aluno
  event_tracker/ — Rastreamento de eventos
  search/        — Busca integrada (usa search-service/search)
  intra/         — Intranet interna
  landing_pages/ — Landing pages via Strapi
  nip/           — NIP (notificacoes internas?)
  salavip/       — Sala VIP
  objetivos/     — Objetivos de estudo
  pagamento_professores/ — Gestao de pagamentos a professores
  external_claims/ — Claims externos
  catalogs/      — Catalogos de conteudo
  jobtracking/   — Rastreamento de jobs
```

---

## Categoria: Apps Mobile

| Repo | Stack | Proposito |
|---|---|---|
| **mobile-estrategia-educacional** | Flutter (Dart), BLoC pattern, Provider | App iOS e Android de todas as verticais. Modulos: LDI (cursos/videos), questoes, simulados, metas, perfil, downloads offline. Consome BFF mobile do monolito (`apps/bff_mobile`). |

### Estrutura Mobile

```
lib/modules/
  ldi/           — Cursos LDI, videos (Vimeo/VideoMyDocuments/YouTube)
  goals/         — Metas e objetivos de estudo
  notifications/ — Notificacoes push
  profile/       — Perfil do aluno
  ...

clients/lib/src/bff/
  ldi/           — Modelos e servicos de API do LDI
  ...
```

---

## Categoria: Microservicos de Dominio

| Repo | Stack | Proposito |
|---|---|---|
| **questions** | Go, PostgreSQL | Microservico de questoes, cadernos, simulados e listas. Independente do monolito. Expoe client Go (`clients/`) para uso interno. |
| **accounts** | Go, PostgreSQL | Dados do usuario (perfil, autenticacao, preferencias). Expoe `accountsclient` Go para outros servicos. |
| **ecommerce** | Go, PostgreSQL, Redis, SQS | Compras de produtos, pedidos, cobrancas, cupons, lotes, liberacao de acessos, integracoes B2B. |
| **user-access** | Go | Controle de acessos da area do aluno — quem tem acesso a qual conteudo. |
| **WebCasts** | Go (multi-service: `service/`, `operator/`, `owncast/`) | Plataforma de lives/webcasts com chat em tempo real (suporta 2000+ espectadores). Usa RTMP para streaming, chat textual, moderacao. Operador usa OBS. |
| **search** | Go, Kafka, OpenSearch | Search Worker — agrega, formata e indexa dados em tempo real no OpenSearch via Kafka (Debezium CDC). Processa eventos de outros servicos e indexa para busca rapida. |
| **search-service** | Go + Node, Solr | Servico de busca legado (Solr). API de busca textual. Pode ser predecessor do `search` moderno. |
| **toggler** | Go + JS | Feature flags e gerenciamento de configuracoes de aplicacao. Tem SDK JS e interface grafica. |
| **warmup-scheduler** | Go, AWS | Agenda pre-aquecimento dos load balancers dos principais servicos (Accounts, Monolito, Questoes, Ecommerce, User-Access, etc.) para evitar cold start. |

---

## Categoria: Frontend Auxiliar / Design System

| Repo | Stack | Proposito |
|---|---|---|
| **coruja-web-ui** | Vue, Storybook | Design system compartilhado (`@estrategiahq/coruja-web-ui`). Componentes reutilizaveis usados por bo-container, front-student e perfil. |
| **perfil** | Vue, Node, Express | Paginas de autenticacao (login, cadastro, logout, recuperacao de senha) e paginas publicas/privadas de perfil do usuario. |

---

## Categoria: Libs Compartilhadas

| Repo | Stack | Proposito |
|---|---|---|
| **backend-libs** | Go | Libs compartilhadas entre squads: `elogger` (logging estruturado), `appcontext`, `athena`. Pacote Go importado pelos outros servicos. |

---

## Categoria: Dados / Analytics

| Repo | Stack | Proposito |
|---|---|---|
| **datachapter-ETLs** | Python, Airflow, AWS (S3, Athena, Glue, Airbyte) | ETLs de dados da plataforma. Airflow para orchestracao, Datalake (Apache Parquet no S3), Athena para queries SQL, Airbyte para integracoes no-code (Google Sheets, ADS). |

---

## Categoria: Infraestrutura

| Repo | Stack | Proposito |
|---|---|---|
| **platform-cluster** | Kubernetes, Argo CD, Helm | Cluster de infraestrutura. Manifestos Argo, containers, apps K8s. |
| **terraform_unificado** | Terraform, AWS | Infraestrutura cloud como codigo. ALB, WAF, CloudFlare (cert, DNS), base configs. |

---

## Mapa de Pistas → Repo Certo

Ao refinar um card Jira, usar este mapa para decidir qual repo investigar:

| Pista no card / Horizontal | Repos a investigar |
|---|---|
| "LDI", "capitulo", "item", "bloco", "video LDI" | `monolito/apps/ldi/` + `front-student/modules/ldi-poc/` |
| "APP", "mobile", "aplicativo", "iOS", "Android" | `mobile-estrategia-educacional/` + `monolito/apps/bff_mobile/` |
| "questao", "caderno", "simulado", "lista" | `monolito/apps/questoes/` + `questions/` |
| "compra", "pedido", "cobranca", "produto", "cupom" | `ecommerce/` + `monolito/apps/ecommerce/` |
| "acesso", "liberacao", "user-access" | `user-access/` |
| "autenticacao", "login", "cadastro", "senha" | `perfil/` + `accounts/` |
| "busca", "search", "OpenSearch", "Solr", "indexacao" | `search/` + `search-service/` + `monolito/apps/search/` |
| "webcast", "live", "streaming", "chat ao vivo" | `WebCasts/` |
| "feature flag", "toggler", "configuracao" | `toggler/` |
| "usuario", "perfil", "conta", "dados pessoais" | `accounts/` |
| "podcast", "cast", "audio" | `monolito/apps/cast/` |
| "material", "pdf", "meus documentos" | `monolito/apps/materiais/` |
| "monitoria", "ao vivo" | `monolito/apps/monitorias/` + `WebCasts/` |
| "coaching" | `monolito/apps/coaching/` |
| "trilha" | `monolito/apps/trilhas_estrategicas/` |
| "ranking" | `monolito/apps/ranking/` |
| "redacao" | `monolito/apps/redacoes/` |
| "BO", "backoffice", "operador" | `bo-container/` + `monolito/apps/bo/` |
| "aluno", "front", "portal" | `front-student/` + `monolito/apps/bff/` |
| "componente", "design system", "coruja-web-ui" | `coruja-web-ui/` |
| "dados", "ETL", "datalake", "analytics" | `datachapter-ETLs/` |
| "infra", "k8s", "deploy", "cluster" | `platform-cluster/` |
| "AWS", "terraform", "ALB", "CloudFlare" | `terraform_unificado/` |
| "warmup", "load balancer", "cold start" | `warmup-scheduler/` |

---

## Multi-tenant (verticais)

Todos os repos de negocio sao multi-tenant:

| Vertical | Slug |
|---|---|
| Concursos Publicos | `concursos` |
| Medicina | `medicina` |
| OAB | `oab` |
| Vestibulares | `vestibulares` |
| Militares | `militares` |
| Carreiras Juridicas | `carreiras-juridicas` |

- **Monolito/Go**: `appcontext.GetVertical(ctx)` e `appcontext.GetUserToken(ctx)`
- **Fronts/Mobile**: header `X-Vertical` em toda chamada HTTP
- **URLs de acesso**: `med.estrategia.com` (medicina), `concursos.estrategia.com`, etc.

---

## Comunicacao entre Repos

```
front-student / bo-container / mobile
        |
        | HTTP (JWT + X-Vertical)
        v
  monolito/apps/bff        (web)
  monolito/apps/bff_mobile (mobile)
        |
        | internal packages / gRPC / HTTP
        v
  questions   accounts   ecommerce   user-access   WebCasts
        |
        | Kafka (CDC via Debezium)
        v
    search (indexa no OpenSearch)
```

---

## Como usar este guia no refinamento

1. Ler o card Jira e identificar o `[Tech] Horizontal` e as pistas na descricao
2. Consultar a tabela "Mapa de Pistas" acima para identificar os repos relevantes
3. Ir direto aos paths listados — nao investigar repos irrelevantes
4. Se o bug envolve `mobile`: sempre investigar tambem `monolito/apps/bff_mobile/` (BFF do app)
5. Se o bug envolve `search/busca`: verificar se e OpenSearch (repo `search/`) ou Solr (`search-service/`)
