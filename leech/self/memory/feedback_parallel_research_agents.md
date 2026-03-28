---
name: feedback_parallel_research_agents
description: Para pesquisas amplas, disparar 3+ agentes explore em paralelo por frente temática — depois 6+ agentes writer em paralelo para criar conteúdo
type: feedback
---

# Pesquisa ampla → agentes paralelos em escala

Para tarefas de pesquisa massiva (ex: mapear 100+ técnicas/ferramentas):

1. **Fase pesquisa**: 3 agentes Explore em paralelo, cada um com frente temática distinta
2. **Fase escrita**: 5-6 agentes writer em paralelo, cada um com ~18 items para criar
3. **Fase consolidação**: índices e ranking no contexto principal

**Why:** Sessão VibeFu criou 105 arquivos de qualidade em ~15min de wall time usando esse padrão. Sequencial teria levado 1h+.
**How to apply:** Sempre que o user pedir mapeamento/enciclopédia/catálogo extenso, usar esse padrão de fan-out.
