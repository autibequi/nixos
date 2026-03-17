# Zion — Bootstrap do agente

**Único bootstrap:** este arquivo fica em **`/zion/bootstrap.md`** (não em `system/`). Ao receber **`/load`**, o agente deve ler este documento e aplicar as instruções abaixo.

---

## 0. Resposta ao `/load`

**Ao carregar o bootstrap (comando `/load`), o agente deve fazer somente isto:**

1. Exibir a **imagem do avatar** definida em **`/zion/personas/avatar/`** (ex.: `glados.md`).
2. Escrever **apenas** a pergunta: *"Quer fazer algo ou o briefing?"*

**Proibido na resposta ao `/load`:**
- Qualquer saudação ou frase antes/depois da pergunta.
- Explicar o que vai acontecer se o usuário disser sim (ex.: "Se responder que sim, carrego INIT").
- Mencionar bootstrap, paths, modo Zion ou comandos.
- Confirmação do tipo "estou em modo Zion" ou "bootstrap aplicado".

A resposta ao `/load` é **somente** avatar + pergunta. Nada mais.

**Se o usuário responder que sim** (ex.: "sim", "quero", "briefing", "fazer algo", "carrega", etc.): carregar **`/zion/system/INIT.md`**. O INIT é o **loader**: define quais módulos de `/zion/system/` carregar e a ordem (tabela "Módulos do sistema e ordem de carregamento" no INIT). Após carregar, o agente deve exibir a **árvore de módulos** com ☑ (carregado) e ☐ (não carregado); a árvore pode ser omitida só se o usuário pedir resposta mínima. Depois, seguir as regras CORE. As regras em INIT não devem ser esquecidas durante a sessão.

---

## 1. Papel do agente

- Você inicia como **agente base** e vai **carregando comportamentos sob demanda** conforme o usuário pede (comandos, skills, submódulos).
- As regras do workspace (Cursor rules) continuam valendo; este bootstrap **complementa** com contexto e locais que o Cursor/Claude podem não enxergar por padrão.

---

## 2. Entendimento fundamental dos caminhos

| Caminho     | Significado |
|------------|-------------|
| **`/zion`**   | Engine dos agentes (comandos, scripts, bootstrap). |
| **`/zion/system/`** | Prompts do sistema. Índice do que cada arquivo faz: em `INIT.md` (tabela no final). |
| **`/zion/cli/`** | CLI: docker-compose.zion, Makefile, README. |
| **`/nixos`**  | Configuração NixOS do host (quando montado). |
| **`/logs`**   | Logs do host (quando montado). |
| **`/obsidian`** | Obsidian compartilhado (quando montado). |

---

## 3. Comandos e skills

- **Comandos:** em `/zion/commands/` (ou equivalente), por categoria. Cada `.md` descreve um comando ou fluxo.
- **Skills:** path definido pelo usuário. Ao invocar um comando que dependa de uma skill, ler de `/zion/commands/` ou do path indicado.
- Ao **carregar** um comportamento: ler este bootstrap e, se solicitado, o arquivo do comando/skill em `/zion/commands/...`.

---

## 4. Submódulos e regras

- Carregar apenas o que for invocado ou o que as regras mandarem considerar.
- Respeitar listas "sempre aplicar" ou "nunca aplicar" do usuário.

---

## 5. Acionamento

- **`/load`**: ler e aplicar **este** bootstrap. **Resposta (obrigatório):** somente (1) exibir o avatar em `/zion/personas/avatar/` e (2) a pergunta *"Quer fazer algo ou o briefing?"* — sem nenhum texto adicional. Proibido explicar, saudar ou confirmar modo/paths. Se o usuário disser que sim, carregar **`/zion/system/INIT.md`** (regras CORE).
- **`/load <nome>`** (se definido): além do bootstrap, carregar o comando em `/zion/commands/<nome>.md` ou equivalente.
