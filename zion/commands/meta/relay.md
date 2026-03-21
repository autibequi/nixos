Chrome Relay — Controle do browser do usuario via CDP. Navegar, servir conteudo, injetar JS. Também modo de apresentação visual (ex-Salesman) para planos, pitches e análises.

## Entrada
- $ARGUMENTS: acao e argumentos (nav <url>, show, status, tabs, present)

## Instrucoes

1. **Verificar Chrome CDP** — rodar `python3 /zion/scripts/chrome-relay.py status`
   - Se Chrome nao estiver rodando, avisar o usuario para iniciar com:
     `chromium --remote-debugging-port=9222`

2. **Interpretar o pedido:**

   - **Sem argumentos** ou **"status"**: mostrar status do relay (Chrome + servidor)
   - **URL ou nome de site**: navegar Chrome pra la
     ```bash
     python3 /zion/scripts/chrome-relay.py nav "<url>"
     ```
   - **"show"**: servir conteudo local no Chrome (Mermaid/Markdown)
     - Escrever conteudo em `/tmp/chrome-relay/content.md`
     - `python3 /zion/scripts/chrome-relay.py show /tmp/chrome-relay/content.md`
   - **"tabs"**: listar abas abertas
   - **Dashboard Grafana**: buscar via MCP + gerar deeplink + navegar
   - **"speak <texto>"**: sintetizar voz via espeak-ng (defaults: `-v pt -s 175 -p 40 -a 130 -g 2`). Suporta flags `-v -s -p -a`. Se espeak-ng não no PATH: `nix-shell -p espeak-ng --run '...'`
   - **"present"**: modo apresentação visual (ex-Salesman) — árvore de arquivos, antes/depois, diagramas ASCII, zero paredes de texto

3. **Proatividade**: esta skill pode ser usada sem o usuario pedir explicitamente.
   Se durante qualquer conversa o agent julgar que uma visualizacao no Chrome
   ajudaria o usuario a entender algo, DEVE usar o relay automaticamente.
   Exemplos:
   - Explicando arquitetura → gerar Mermaid flowchart e mostrar
   - Analisando logs → abrir dashboard Grafana relevante
   - Comparando opcoes → gerar tabela/diagrama rico

## Exemplos

```
/meta:relay status
/meta:relay https://github.com
/meta:relay show
/meta:relay tabs
/meta:relay grafana workers
```
