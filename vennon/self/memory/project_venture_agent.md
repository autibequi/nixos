---
name: project_venture_agent
description: Agente venture — business discovery que transforma ideias em projetos completos. Substitui jonathas como agente generico de negocios.
type: project
---

Agente **venture** em `self/agents/venture/agent.md`. Sonnet, every60min.

Pipeline de Discovery em 10 fases:
1. Mercado (TAM/SAM/SOM, buscas, tendencias)
2. Concorrencia (reviews, gaps, pricing, quadrante)
3. Modelo de negocio (revenue, unit economics, tributario)
4. SWOT + Riscos (probabilidade × impacto, mitigacoes)
5. Cenarios financeiros (3 cenarios, graficos MRR)
6. Produto (MVP, stack, schema, API, telas)
7. Roadmap (6 fases, backlog 50+, stubs pesquisa)
8. Execucao (MASTIGADO dia-a-dia, CUIDADOS riscos, GTM personas+copy)
9. Compilado (FULLSTRATEGY 20+ Mermaid)
10. INDEX (ponto de entrada exploratório)

Estrutura padrao de pastas: INDEX.md + FULLSTRATEGY.md + MASTIGADO.md + CUIDADOS.md + README.md + codigo/ + docs/

Desenvolvido na sessao Jonathas (2026-03-28) — testado com projeto imobiliario RJ que gerou 88+ arquivos.

**Why:** Pedro precisa de agente que pega qualquer ideia e gera material completo para terceiros (primo, parceiros) executarem.
**How to apply:** Invocar com `venture` como subagent_type, ou agendar com every60 para iterar projetos existentes em workshop/.
