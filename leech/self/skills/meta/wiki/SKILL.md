---
name: meta:wiki
description: "Wiki command — dashboard do conhecimento, add/remove tópicos, busca nos artigos. Acesso à Wikipedia pessoal mantida pelo Wikister."
trigger: "/meta:wiki"
---

# /meta:wiki — Wiki Pessoal

Skill de acesso à Wikipedia pessoal do Pedro, mantida pelo agente Wikister em `/workspace/obsidian/wiki/`.

---

## Subcomandos

| Comando | Ação |
|---------|------|
| `/meta:wiki` | Dashboard: cobertura, artigos recentes, gaps |
| `/meta:wiki add <topico>` | Adiciona tópico à fila de investigação do Wikister |
| `/meta:wiki remove <path>` | Remove artigo ou exclui tópico da rotação |
| `/meta:wiki search <query>` | Busca nos artigos wiki com excerpts |

---

## /meta:wiki — Dashboard

Executar ao ser invocado sem subcomando:

### 1. Contar artigos por área

```bash
WIKI=/workspace/obsidian/wiki
echo "estrategia/projetos: $(ls $WIKI/estrategia/projetos/*.md 2>/dev/null | wc -l)"
echo "estrategia/pessoas:  $(ls $WIKI/estrategia/pessoas/*.md  2>/dev/null | wc -l)"
echo "estrategia/jira:     $(ls $WIKI/estrategia/jira/*.md     2>/dev/null | wc -l)"
echo "estrategia/notion:   $(ls $WIKI/estrategia/notion/*.md   2>/dev/null | wc -l)"
echo "host:                $(ls $WIKI/host/*.md                2>/dev/null | wc -l)"
echo "leech:               $(ls $WIKI/leech/*.md               2>/dev/null | wc -l)"
echo "pedrinho:            $(ls $WIKI/pedrinho/*.md            2>/dev/null | wc -l)"
```

### 2. Artigos mais recentes (últimas 5 atualizações)

```bash
find /workspace/obsidian/wiki -name "*.md" \
  ! -name "README.md" \
  -exec stat --format="%Y %n" {} \; \
  | sort -rn | head -5 \
  | awk '{print $2}'
```

### 3. Ler memory.md do Wikister

```bash
cat /workspace/obsidian/bedrooms/wikister/memory.md
```

Extrair: último ciclo, próximo ciclo agendado, queue pendente.

### 4. Renderizar dashboard ASCII (mobile-friendly, ≤ 60 chars por linha)

```
WIKISTER — Knowledge Base
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Area                 Arts  Bar
estrategia/projetos   N    ██░░
estrategia/pessoas    N    ██░░
estrategia/jira       N    █░░░
estrategia/notion     N    ░░░░
host                  N    ███░
leech                 N    ████
pedrinho              N    ██░░
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: N artigos
Ciclo: #N | Ultimo: HH:MM UTC
Proximo: HH:MM UTC
Queue: N topicos pendentes
```

Barra proporcional ao número de artigos (max para a área com mais artigos = ████).

Se queue não vazia, listar:
```
Queue:
  - topico/a-investigar
  - outro/topico
```

---

## /meta:wiki add \<topico\>

Adiciona tópico à fila de investigação do Wikister.

1. Ler `memory.md` do Wikister
2. Adicionar item ao campo `queue` (lista YAML)
3. Salvar `memory.md`
4. Confirmar: `Adicionado à fila: <topico>`

**Exemplos de tópicos válidos:**
- `estrategia/projetos/ecommerce` — investigar repo ecommerce
- `estrategia/pessoas/washington` — investigar dev Washington
- `pedrinho/hobbies` — artigo sobre hobbies do Pedro
- `host/waybar` — artigo sobre Waybar no NixOS
- `leech/hermes` — artigo sobre o agente Hermes

---

## /meta:wiki remove \<path\>

Remove artigo ou exclui tópico da rotação.

1. Verificar se `<path>` é um arquivo existente:
   ```bash
   ls /workspace/obsidian/wiki/<path>.md
   ```
2. **Se existe:** deletar o arquivo + remover link de `wiki/README.md`
3. **Se não existe:** adicionar em `excluded_topics` no `memory.md` do Wikister
   (Wikister não vai investigar esse tópico na rotação automática)
4. Confirmar ação realizada

---

## /meta:wiki search \<query\>

Busca nos artigos wiki com contexto.

```bash
grep -r --include="*.md" -i -n "<query>" \
  /workspace/obsidian/wiki/ \
  --color=never \
  -C 2
```

Processar resultados:
- Agrupar por arquivo
- Mostrar path relativo a `wiki/`
- Mostrar até 3 excerpts por arquivo (contexto de 2 linhas)
- Limite: 10 arquivos máximo

Formato de saída:

```
BUSCA: "<query>" — N resultados em M artigos
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
estrategia/projetos/monolito.md (3 ocorrencias)
  L42: ... contexto da linha ...
  L87: ... contexto da linha ...

leech/agentes.md (1 ocorrencia)
  L15: ... contexto da linha ...
```

Se zero resultados:
```
Nenhum artigo encontrado para "<query>"
Sugestao: /meta:wiki add <topico-relacionado>
```
