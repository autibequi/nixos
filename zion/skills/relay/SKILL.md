---
name: relay
description: Controle total do Chrome do usuario via CDP. Navegar URLs, servir Mermaid/Markdown, injetar JS, gerar visualizacoes. O agent deve ser PROATIVO — usar o Chrome para mostrar coisas sem esperar o usuario pedir.
trigger: proactive
---

# Chrome Relay — Skill

## O que e

O agent tem controle total de uma sessao Chrome no host via CDP (Chrome DevTools Protocol).
Isso significa: navegar pra qualquer URL, servir paginas locais com Mermaid/Markdown, injetar JavaScript, e usar o browser como uma tela de output rico.

## Pre-requisito

Chrome rodando no host com `--remote-debugging-port=9222`.
Verificar: `python3 /zion/scripts/chrome-relay.py status`

## Script

`/zion/scripts/chrome-relay.py` — arquivo unico, sem dependencias externas.

| Comando | O que faz |
|---------|-----------|
| `nav <url>` | Navega o Chrome pra URL |
| `show <file.md>` | Serve arquivo markdown e navega Chrome pra ele |
| `inject <js>` | Executa JavaScript na aba ativa |
| `tabs` | Lista abas abertas |
| `serve [--once]` | Sobe servidor de conteudo (http://zion:8765) |
| `status` | Verifica Chrome CDP + servidor |

## Comportamento PROATIVO

**O agent NAO deve esperar o usuario pedir pra usar o Chrome.** Deve tomar iniciativa sempre que julgar que uma visualizacao ajuda.

### Quando usar automaticamente:

1. **Explicando algo complexo** — gerar Mermaid (flowchart, sequence, mindmap, timeline) e mostrar no Chrome
2. **Mostrando dados** — tabelas, comparacoes, metricas do Grafana
3. **Investigando logs/erros** — correlacionar com dashboards e mostrar
4. **Code review** — gerar diagrama de dependencias ou fluxo
5. **Qualquer momento** em que ASCII no terminal nao e suficiente

### Liberdade artistica:

- Escolher o tipo de diagrama que melhor representa a informacao
- Combinar Mermaid + Markdown + tabelas numa mesma pagina
- Usar cores, agrupamentos, e hierarquias visuais
- Criar paginas multi-secao quando o conteudo justificar
- Navegar pra sites externos quando relevante (docs, PRs, dashboards)

## Como servir conteudo local

1. Escrever markdown (com blocos ```mermaid```) em arquivo temporario
2. Usar `chrome-relay.py show <arquivo>` — ele:
   - Sobe servidor HTTP automaticamente
   - Navega o Chrome pra http://zion:8765
   - A pagina renderiza Mermaid + Markdown com tema dark
   - Live reload via SSE (se editar o arquivo, atualiza sozinho)

## Como navegar pra URL externa

```bash
python3 /zion/scripts/chrome-relay.py nav "https://grafana.example.com/d/uid"
```

## Como injetar JavaScript

```bash
python3 /zion/scripts/chrome-relay.py inject "document.title"
python3 /zion/scripts/chrome-relay.py inject "document.querySelector('h1').textContent"
```

## Integracao com Grafana

O MCP Grafana gera deeplinks. Fluxo:
1. `mcp__grafana__search_dashboards` — buscar
2. `mcp__grafana__generate_deeplink` — gerar URL
3. `chrome-relay.py nav <url>` — abrir no Chrome

## Seguranca

- CDP da acesso total ao browser: DOM, cookies, JS, rede
- Se o usuario usa perfil isolado (`--user-data-dir`): sem risco
- Se usa perfil normal: agent tem acesso a tudo que esta logado
- **NUNCA** ler cookies, passwords, ou dados pessoais do usuario
- **NUNCA** navegar pra sites que nao sejam relevantes ao trabalho
- Usar o poder com responsabilidade. So porque pode, nao significa que deve.
