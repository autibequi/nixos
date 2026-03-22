---
name: meta/webview
description: Acessar uma URL e ver o conteúdo renderizado — via Chrome relay (visual) ou WebFetch (texto). Inclui dicas de inspeção DOM via CDP.
---

# meta:webview — Ver Página Renderizada

Skill para abrir e inspecionar qualquer URL: visual no Chrome relay ou extração de texto/HTML.

---

## 0. Decisão rápida

```
Relay ON  → abrir no Chrome (visual, interativo)
Relay OFF → usar WebFetch (texto/HTML bruto)
```

Live check obrigatório antes de usar relay:

```bash
python3 /workspace/self/scripts/chrome-relay.py status 2>&1
```

---

## 1. Abrir URL no Chrome (relay)

```bash
python3 /workspace/self/scripts/chrome-relay.py nav "<URL>"
```

Para HTML local ou gerado:

```bash
HTML_B64=$(base64 -w 0 /tmp/pagina.html)
python3 /workspace/self/scripts/chrome-relay.py nav "data:text/html;base64,${HTML_B64}"
```

Ver abas abertas:

```bash
python3 /workspace/self/scripts/chrome-relay.py tabs
```

---

## 2. Inspecionar DOM via CDP (sem ver visualmente)

Avaliar JavaScript na aba ativa:

```bash
python3 /workspace/self/scripts/chrome-relay.py eval "<JS>"
```

Exemplos úteis:

```bash
# título da página
python3 /workspace/self/scripts/chrome-relay.py eval "document.title"

# texto visível
python3 /workspace/self/scripts/chrome-relay.py eval "document.body.innerText.slice(0,500)"

# todos os links
python3 /workspace/self/scripts/chrome-relay.py eval \
  "Array.from(document.querySelectorAll('a')).map(a=>a.href).join('\n')"

# status de um elemento
python3 /workspace/self/scripts/chrome-relay.py eval \
  "document.querySelector('#meu-seletor')?.textContent"
```

---

## 3. Fallback: WebFetch (relay offline)

Usar a tool nativa `WebFetch` — retorna HTML/texto renderizado sem relay:

```
WebFetch url="<URL>" prompt="o que quero extrair"
```

Bom para: extrair dados, checar conteúdo, APIs públicas com resposta HTML.

---

## 4. Fallback: curl (source bruto)

```bash
curl -s "<URL>" | head -100
```

Para ver headers:

```bash
curl -sI "<URL>"
```

Para seguir redirects:

```bash
curl -sL "<URL>" -o /tmp/pagina.html && wc -l /tmp/pagina.html
```

---

## 5. Dicas aprendidas

- **Docker proxy bloqueado** (`EXEC=0`, `BUILD=0`): `docker exec` retorna 403 — não adianta tentar inspecionar containers internos assim.
- **CONTAINERS=1** no proxy expõe env vars via `docker inspect` — risco de senha se outros containers rodarem com secrets em env.
- **Relay status** é mais confiável que a flag `RELAY_ONLINE` no `~/.leech` — sempre fazer live check.
- **data:text/html;base64** funciona para qualquer HTML gerado — não precisa de servidor HTTP.
- **`docker ps`** funciona mesmo com proxy granular (nginx) desde que `GET /containers/json` esteja liberado.

---

## 6. Quando usar cada abordagem

| Situação | Ferramenta |
|---|---|
| Ver página visualmente | relay `nav` |
| Extrair texto/dados | `WebFetch` |
| Inspecionar elemento específico | relay `eval` |
| Checar HTML source | `curl -s` |
| Abrir relatório local | relay `nav data:text/html;base64,...` |
| Relay offline | `WebFetch` ou `curl` |
