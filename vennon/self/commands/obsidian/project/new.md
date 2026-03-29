---
name: obsidian:project:new
description: Cria um novo projeto com briefing, card no DASHBOARD e pasta em projects/. Wizard passo a passo.
---

# /meta:new-project — Criar Novo Projeto

> Resultado final SEMPRE: card no DASHBOARD + pasta projects/<nome>/BRIEFING.md

---

## Passo 1 — Entender o projeto

Perguntar ao user (ou inferir do contexto):

1. **Nome** — slug curto, sem espacos (ex: `imobiltracker`, `blog-pessoal`, `saas-metricas`)
2. **Objetivo** — 1-2 frases do que o projeto faz/entrega
3. **Tipo** — qual a natureza:
   - `produto` — software com codigo, MVP, deploy
   - `pesquisa` — investigacao, analise, relatorio
   - `conteudo` — blog, wiki, documentacao
   - `infra` — configuracao, devops, NixOS
   - `outro` — especificar

## Passo 2 — Selecionar agente

Apresentar os agentes disponiveis e recomendar com base no tipo:

| Tipo | Agente recomendado | Motivo |
|------|-------------------|--------|
| produto (MVP, startup, negocio) | **venture** | Pensa como investidor, valida antes de construir |
| codigo estrategia (Go/Vue/Nuxt) | **coruja** | Especialista dos 3 repos |
| codigo generico | **hefesto** | Mestre construtor, todas as skills |
| pesquisa/analise | **gandalf** | Modo EXPLORE + DOCUMENT |
| conteudo/wiki | **gandalf** | Modo DOCUMENT |
| infra/NixOS/docker | **hefesto** | Conhece vennon/linux e vennon/container |
| saude/limpeza/rotina | **keeper** | Especialista em manutencao |
| feeds/curadoria | **paperboy** | Motor de descoberta |

Se o user quiser outro agente ou nao souber: usar **hefesto** (default universal).

## Passo 3 — Definir recorrencia

Perguntar:

- **E continuo?** (ronda sem fim, tipo manter um produto vivo)
  - Sim → `#ronda` + `#everyXmin`
  - Nao → card one-off (sem #ronda)

- **Frequencia** (se continuo):
  - `#every10min` — urgente, monitoramento
  - `#every30min` — ativo, iteracao rapida
  - `#every60min` — padrao, ciclos normais
  - `#every120min` — baixa prioridade, pesquisa lenta

- **Modelo**:
  - `#haiku` — tasks simples, pesquisa, limpeza
  - `#sonnet` — codigo, analise, planejamento
  - `#opus` — pensamento profundo, arquitetura, decisoes complexas

## Passo 4 — Criar o BRIEFING.md

Criar `/workspace/obsidian/projects/<nome>/BRIEFING.md` seguindo o template:

```markdown
# <Nome> — Briefing do Projeto

> <Objetivo em 1-2 linhas>
> Este arquivo e lido pelo agente executor antes de cada ciclo.

## Contexto

<Descricao mais detalhada: o que e, pra quem, por que existe>

## Estrutura

<Arvore de pastas do projeto — preencher conforme cresce>

## O que fazer a cada ciclo

1. Ler este briefing
2. <Acao principal>
3. <Acao secundaria>
4. Registrar resultado em bedrooms/<agente>/memory.md

## Prioridade

1. <Prioridade maxima>
2. <Prioridade media>
3. <Prioridade baixa>

## Regras

- <Regra especifica do projeto>
- Artefatos aqui — tudo em projects/<nome>/
- 1 item por ciclo (foco e profundidade)

## Estado Atual

<Preencher apos primeiro ciclo>
```

## Passo 5 — Criar o card no DASHBOARD

Adicionar na coluna `## TODO` do DASHBOARD:

**Se continuo (#ronda):**
```
- [ ] **<nome>** #<agente> #<modelo> #ronda #<everyXmin> `last:NEVER` `briefing:projects/<nome>/BRIEFING.md`
```

**Se one-off:**
```
- [ ] **<nome>** #<agente> #<modelo> `briefing:projects/<nome>/BRIEFING.md`
```

`last:NEVER` forca o Hermes a despachar no proximo tick.

## Passo 6 — Confirmar

Mostrar ao user:

```
  ██████████████████████████████████████████
  █  SUCESSO                               █
  ██████████████████████████████████████████
  │                                        │
  │   Projeto <nome> criado                │
  │                                        │
  │   Pasta:    projects/<nome>/           │
  │   Briefing: projects/<nome>/BRIEFING.md│
  │   Agente:   #<agente>                  │
  │   Modelo:   #<modelo>                  │
  │   Tipo:     <continuo|one-off>         │
  │   Card:     adicionado ao DASHBOARD    │
  │                                        │
  │   Proximo yaa tick vai despachar.      │
  │                                        │
  ╰────────────────────────────────────────╯
```

---

## Regras do BRIEFING.md

Ler `self/commands/meta/briefing-rules.md` para o formato obrigatorio.
