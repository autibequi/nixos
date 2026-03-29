---
name: meta/art/chrome
description: Chrome relay para arte — voz (speak), templates artisticos (eye, glados) e controle de abas. Para flowcharts e visualizacoes de dados, ver meta/holodeck.
---

# Chrome Relay — Arte

> Para dados, flowcharts, dashboards: usar `meta/holodeck`.
> Aqui: voz, animacoes artisticas, controle do browser.

---

## Verificar relay

```bash
python3 /workspace/self/scripts/chrome-relay.py status 2>&1
```

Comandos basicos: `nav <url>`, `tabs`, `inject <js>` — detalhes completos em `meta/holodeck`.

---

## Voz (speak)

```bash
python3 /workspace/self/scripts/chrome-relay.py speak "<texto>"
```

Defaults: `-v pt -s 175 -p 40 -a 130 -g 2`
Se espeak-ng nao no PATH: `nix-shell -p espeak-ng --run '...'`

Para voz GLaDOS especifica: `~/.claude/scripts/glados-speak.sh`

---

## Templates artisticos

### eyes.html — Rosto dot-matrix fullscreen

```bash
cp /workspace/self/skills/meta/art/templates/eyes.html /tmp/chrome-relay/eyes.html
python3 /workspace/self/scripts/chrome-relay.py nav "http://127.0.0.1:8765/eyes.html"
python3 /workspace/self/scripts/chrome-relay.py inject "document.documentElement.requestFullscreen()"
```

Controle via inject:
```js
EYE.next()      // proxima expressao
EYE.prev()      // anterior
EYE.goto(N)     // vai para indice N
EYE.play()      // retoma loop
EYE.pause()     // pausa
EYE.list()      // lista steps
```

Versao com SEQUENCE editavel: `templates/eye/index.html` + `engine.js`

### glados.html — Avatar GLaDOS animado

```bash
cp /workspace/self/skills/meta/art/templates/glados.html /tmp/chrome-relay/glados.html
python3 /workspace/self/scripts/chrome-relay.py nav "http://127.0.0.1:8765/glados.html"
```

---

## Templates

| Arquivo | Descricao |
|---|---|
| `templates/eye.html` | Olho unico dot-matrix |
| `templates/eyes.html` | Rosto completo, 6 emocoes, SEQUENCE configuravel |
| `templates/eye/` | Versao modular (index.html + engine.js) |
| `templates/glados.html` | Avatar GLaDOS |

---

## Canvas Colaborativo

Ferramenta de diagramacao interativa — desenhada do zero, sem dependencias.
Fonte: `host/vennon/tools/chrome/canvas/index.html`

```bash
# Servir e abrir
cp /workspace/host/vennon/tools/chrome/canvas/index.html /tmp/chrome-relay/canvas.html
python3 /workspace/self/scripts/chrome-relay.py nav "http://vennon:8765/canvas.html"
python3 /workspace/self/scripts/chrome-relay.py inject "document.documentElement.requestFullscreen()"
```

### Ferramentas do usuario
- **pen** — desenho livre
- **node** — nos com label, arrastaveis
- **edge** — arestas com seta e label entre nos
- **text** — texto livre posicionavel
- **erase** — apaga elementos

### API para injecao via relay
```js
CANVAS.addNode(x, y, 'Label', '#cor')    // adiciona no
CANVAS.addEdge('FromLabel', 'ToLabel', 'label aresta')  // conecta nos por label
CANVAS.addText(x, y, 'texto', '#cor')    // adiciona texto
CANVAS.layout('circle')                  // auto-layout: 'circle' | 'grid'
CANVAS.state()                           // retorna JSON com nos, arestas, textos
CANVAS.clear()                           // limpa tudo
```

### Fluxo colaborativo
1. Abrir canvas no Chrome
2. Usuario interage (move nos, adiciona, desenha)
3. Injetar `CANVAS.state()` para ver estado atual
4. Injetar modificacoes em cima do que o usuario fez
5. Iterar
