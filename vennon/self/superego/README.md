# Superego — Regras Globais do Sistema

> Fonte unica de verdade para regras que se aplicam a TODOS os agentes.
> Editar aqui = editar pra todos ao mesmo tempo.
> Todo agente DEVE ler este diretorio no boot de cada ciclo.

---

## Arquivos

| Arquivo | Conteudo |
|---------|----------|
| `leis.md` | As leis do sistema — proibido, obrigatorio, penalidades |
| `ciclo.md` | Protocolo completo de execucao (boot → executar → finalizar → reagendar) |
| `dashboard.md` | Como funciona o DASHBOARD, formato de cards, quem pode editar |
| `bedrooms.md` | Estrutura obrigatoria do quarto (DIARIO/DESKTOP/ARCHIVE) |
| `obsidian-rules.md` | Mapa do vault, territorios, semantica dos espacos |
| `comunicacao.md` | Inbox, outbox, feed.md, news/, alertas — canais oficiais |

---

## Boot minimo por tipo de agente

**Ronda simples (haiku):**
```bash
cat /workspace/self/superego/leis.md
cat /workspace/self/superego/ciclo.md
cat /workspace/obsidian/bedrooms/<NOME>/memory.md
```

**Ronda complexa / implementacao (sonnet/opus):**
```bash
cat /workspace/self/superego/leis.md
cat /workspace/self/superego/ciclo.md
cat /workspace/self/superego/bedrooms.md
cat /workspace/self/superego/comunicacao.md
cat /workspace/obsidian/bedrooms/<NOME>/memory.md
```

**Hermes / scheduler:**
```bash
cat /workspace/self/superego/leis.md
cat /workspace/self/superego/dashboard.md
cat /workspace/self/superego/comunicacao.md
```

---

> "A lei nao e restricao — e o que permite que o sistema dure."
