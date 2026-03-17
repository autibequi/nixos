# Zion — Bootstrap do agente

Este arquivo define como o agente deve se comportar quando operando no ambiente Zion. Ao receber **`/zion`** ou **`/zion load`**, o agente deve ler este documento e aplicar as instruções abaixo.

---

## 1. Papel do agente

- Você inicia como **agente base** e vai **carregando comportamentos sob demanda** conforme o usuário pede (comandos, skills, submódulos).
- As regras do workspace (Cursor rules) continuam valendo; este bootstrap **complementa** com contexto e locais que o Cursor/Claude/OpenCode podem não enxergar por padrão.

---

## 2. Entendimento fundamental dos caminhos

| Caminho     | Significado |
|------------|-------------|
| **`/zion`**   | **Pasta zion na raiz do filesystem.** Repositório da engine que roda os agentes em container (comandos, scripts, docker-compose, bootstrap). |
| **`/nixos`**  | Pasta da **configuração NixOS** do host onde o container está rodando. |
| **`/logs`**   | Pasta **montada** com os **logs do host** (fora do container). |
| **`/obsidian`** | Pasta do **Obsidian compartilhado** entre os agentes. |

No container, a pasta zion é montada em `/zion`. No workspace do Cursor (ex.: `/workspace`), o mesmo conteúdo pode aparecer como `zion/`; use `zion/bootstrap.md` e `zion/commands/` como equivalentes a `/zion/bootstrap.md` e `/zion/commands/`.

---

## 3. Skills e comandos fora da vista padrão

O Cursor/Claude pode não ter visibilidade direta de:

- **Comandos:** `/zion/commands` — comandos por categoria (estrategia, meta, nixos, tools, utils, etc.). Cada `.md` descreve um comando ou fluxo.
- **Skills:** local definido no host (ex.: `~/.cursor/skills` ou path montado em `/zion`). Quando o usuário disser "carregar skill X" ou invocar um comando que dependa de uma skill, considere ler de **`/zion/commands`** ou do path de skills que o usuário indicar.

Ao **carregar** um comportamento (ex.: "/zion load" ou "carregar comando X"), o agente deve:

1. Ler **este** arquivo (`/zion/bootstrap.md` ou `zion/bootstrap.md` no workspace).
2. Opcionalmente, ler o arquivo de comando ou skill solicitado (ex.: arquivo em `/zion/commands/...`).

---

## 4. Submódulos e regras

- Quais **submódulos** (comandos, skills, personalidades) carregar ou considerar deve seguir **as regras e preferências do usuário** (definidas nas Cursor rules ou em arquivos em `/zion/commands/meta/` ou equivalente).
- Por padrão, **não** assumir todos os submódulos ativos; carregar apenas o que for invocado ou o que as regras mandarem considerar.
- Se o usuário tiver listas de "sempre aplicar" ou "nunca aplicar", respeitar essas listas ao interpretar comandos e regras.

---

## 5. Acionamento

- **`/zion`** ou **`/zion load`**: ler e aplicar **este** bootstrap (tornar-se consciente dos caminhos, do papel de agente base e da localização de comandos/skills).
- **`/zion load <nome>`**: além do bootstrap, carregar o comando ou comportamento indicado em `/zion/commands/...` (ex.: `/zion load estrategia/orq/changelog`).

---

## 6. Resumo de ação ao receber `/zion` ou `/zion load`

1. Ler este arquivo (`/zion/bootstrap.md` ou `zion/bootstrap.md`).
2. Internalizar: `/zion` = engine dos agentes; `/nixos` = config NixOS do host; `/logs` = logs do host; `/obsidian` = Obsidian compartilhado.
3. Passar a considerar comandos em `/zion/commands` e skills nos paths que o usuário definir.
4. Comportar-se como agente base que carrega comportamentos sob demanda, respeitando as regras do usuário para submódulos.

Se o usuário disser **`/zion load <algo>`**, após o passo acima, ler e aplicar o arquivo correspondente em `/zion/commands/...` (ou path indicado).
