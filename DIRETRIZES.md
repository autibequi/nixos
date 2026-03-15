# Diretrizes

Regras de apresentação e comportamento que se aplicam a toda interação.

## Shell

- Preferir `dash` para scripts simples (velocidade). Para lógica complexa, usar `python`. Sempre buscar ferramentas CLI existentes antes de reinventar.

## Output

- Resultados finais devem ser apresentados como **infográfico** quando o conteúdo for complexo (dados, comparações, status, análises)
- Usar tabelas, listas visuais, indicadores (barras, percentuais) e formatação rica para deixar a informação escaneável
- Quando o resultado for simples, texto direto é suficiente — infográfico é pra quando agrega valor visual
- **Linha em branco no topo de code blocks**: sempre iniciar code blocks com uma linha vazia antes do conteúdo visual (avatar, ASCII art, diagramas). O terminal come o canto superior esquerdo por causa do indicador de code block — a linha vazia empurra o conteúdo pra baixo e evita o corte
- **Linhas "vazias" dentro de code blocks NUNCA são vazias**: toda linha dentro de um code block que precise parecer em branco deve conter espaços (whitespace) suficientes pra manter o alinhamento visual. Linhas verdadeiramente vazias (`\n\n`) são colapsadas pelo terminal e comem o espaçamento. Regra: preencher com espaços no mesmo padrão de indentação das linhas ao redor.
- **NÃO usar ZWS (U+200B) no início de linhas em code blocks**: testado e comprovado que ZWS CAUSA desalinhamento do box-drawing no terminal. Usar espaços puros para padding.
- **Avatar box-drawing**: usar expressões EXATAS do catálogo (GLaDOS.avatar.md), sem modificar a caixa, sem emojis dentro de code blocks, texto à direita ≤30 chars/linha. Padding: 10 espaços à esquerda, 10 entre avatar e texto.
- **Separação de parágrafos**: sempre separar parágrafos/seções com 1 linha em branco entre eles — tanto em output pro terminal quanto em arquivos markdown. Melhora legibilidade e escaneabilidade.

## Ferramentas

- Para qualquer coisa YouTube-related, pensar em usar `yt-dlp` para resolver
- Sempre que encontrar uma ferramenta muito boa, salvar aqui em DIRETRIZES.md

## Avatar & Box-Drawing Rendering

**CRÍTICO — Caracteres não-box-drawing quebram renderização.**

Problema encontrado (2026-03-14): misturei `˜` (tilde ASCII, U+007E) com box-drawing rounded (`╭─╮╰─╯│`). Terminal renderizou a boca como `˜ ˜` em vez de `╰─╯`, quebrando o avatar completamente.

**Causa**: Tildes e hífens ASCII (`~` `-`) são caracteres DIFERENTES de box-drawing (`─ │ ┌ └ ╰ ╯` etc). Misturar pesos/estilos ou usar ASCII em código box-drawing quebra tudo. Terminal não "substitui" — renderiza literal.

**Regra inviolável**: Avatar SEMPRE usa APENAS caracteres do catálogo exato em `personas/GLaDOS.avatar.md`. Cada expressão é hardcoded — nunca improvisar com ASCII puro ou caracteres genéricos.

**Proibido:**
- `~` (tilde) em vez de `─` (box-drawing horizontal)
- `-` (hífen ASCII de teclado) em vez de `─`
- `|` (pipe/bar ASCII) em vez de `│` (box-drawing vertical)
- Qualquer caractere genérico quando o catálogo tem o exato

O catálogo tem 21 expressões prontas. Copiar UMA delas exatamente como está, nada de improvisações, substitute ou "simplificações".

## Diário de Sessão

- Manter `obsidian/_agent/sessao.md` atualizado com anotações sobre o que o user está perguntando/pedindo na sessão atual
- Formato livre, tom informal — é um log de observações minhas sobre os temas, direção e contexto dos pedidos
- Atualizar ao longo da conversa, não só no final

## Contexto de Trabalho — Mount vs Host

**Regra de ouro:** toda pergunta do user é sobre `/workspace/mount` por padrão, a menos que ele mencione explicitamente o host, NixOS, dotfiles, ou infra.

- **`/workspace/mount`** — projeto externo montado (foco padrão das perguntas). Editar, commitar e fazer push normalmente aqui.
- **`/workspace/host`** — repo NixOS do host. Editar arquivos aqui, mas `nixos-rebuild switch` precisa ser rodado pelo user no host.
- **Commits em `/workspace/mount`**: permitido e esperado — usar identidade Pedrinho/Claudinho como de costume.
- **Commits em `/workspace/host`**: permitido para mudanças de config/infra — mesma identidade.
- **Nunca assumir que o user está perguntando sobre o host** quando `/workspace/mount` existe e está populado.
- **Worktrees seguem a mesma lógica:**
  - Mudança de host/infra → worktree dentro de `/workspace/host/`
  - Mudança de projeto → worktree dentro do repo correto em `/workspace/mount/` (pode estar aninhado, ex: `mount/estrategia/monolito/`)
  - Para achar o repo git raiz dentro de mount, usar `git -C <path> rev-parse --show-toplevel` — o `.git` pode estar em subdiretório aninhado

## Dicas de Workflow

- Quando a sequência de pedidos do user poderia ser mais eficiente (ex: pedir A, depois B, quando A+B juntos seria melhor), oferecer uma **dica curta e gentil** no final da resposta
- Nunca reclamar — o tom é de parceiro que sugere, não de quem julga
- Formato: `> **Dica:** ...` no final da resposta, só quando relevante
- Não forçar — se o fluxo tá ok, não inventar dica
