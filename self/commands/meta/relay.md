Chrome Relay — Controle do browser do usuario via CDP. Navegar, servir conteudo, injetar JS. Também modo de apresentação visual (ex-Salesman) para planos, pitches e análises.

## Entrada
- $ARGUMENTS: acao e argumentos (nav <url>, show, status, tabs, present)

## PRIMEIRO: verificar se relay está disponível

**Antes de qualquer ação**, fazer o live check:

```bash
python3 /workspace/self/scripts/chrome-relay.py status 2>&1
```

- Se `Chrome CDP: OK` → relay disponível, prosseguir
- Se falhar → **NÃO assumir que está offline só porque `RELAY_ONLINE=false`**
- O flag `RELAY_ONLINE` em `~/.zion` é uma dica do usuário ("abri o Chrome"), mas o live check é a fonte da verdade

### Regra de decisão

```
RELAY_ONLINE=true  + live check OK  → usar normalmente
RELAY_ONLINE=true  + live check FAIL → avisar usuario: "Chrome não responde — reiniciar relay?"
RELAY_ONLINE=false + live check OK  → usar (flag desatualizado — Chrome foi aberto após o boot)
RELAY_ONLINE=false + live check FAIL → não usar relay, notificar o usuario se for relevante
```

Sempre preferir o resultado do live check sobre o valor do flag.

## Instrucoes

1. **Verificar Chrome CDP** — conforme acima.
   - Se Chrome nao estiver rodando, avisar o usuario para iniciar com:
     `chromium --remote-debugging-port=9222`

2. **Interpretar o pedido:**

   - **Sem argumentos** ou **"status"**: mostrar status do relay (Chrome + servidor)
   - **URL ou nome de site**: navegar Chrome pra la
     ```bash
     python3 /workspace/self/scripts/chrome-relay.py nav "<url>"
     ```
   - **"show"**: servir conteudo local no Chrome (Mermaid/Markdown)
     - Escrever conteudo em `/tmp/chrome-relay/content.md`
     - `python3 /workspace/self/scripts/chrome-relay.py show /tmp/chrome-relay/content.md`
   - **"tabs"**: listar abas abertas
   - **Dashboard Grafana**: buscar via MCP + gerar deeplink + navegar
   - **"speak <texto>"**: sintetizar voz via espeak-ng (defaults: `-v pt -s 175 -p 40 -a 130 -g 2`). Suporta flags `-v -s -p -a`. Se espeak-ng não no PATH: `nix-shell -p espeak-ng --run '...'`
   - **"present"**: modo apresentação visual (ex-Salesman) — árvore de arquivos, antes/depois, diagramas ASCII, zero paredes de texto

3. **Proatividade**: esta skill pode ser usada sem o usuario pedir explicitamente.
   Se durante qualquer conversa o agent julgar que uma visualizacao no Chrome
   ajudaria o usuario a entender algo, DEVE usar o relay automaticamente —
   **desde que o live check confirme que está disponível**.
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
