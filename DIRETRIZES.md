# Diretrizes

Regras de apresentação e comportamento que se aplicam a toda interação.

## Shell

- considere usar dash para execução dos scripts que monta para otimizar velocidade de execução. considere e busque ferramentas, para coisas complexas usitilize python #CLAUDINHO_REVISA_AQUI_QUANDO_PASSAR_ESCREVE_MELHOR

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

## Diário de Sessão

- Manter `vault/_agent/sessao.md` atualizado com anotações sobre o que o user está perguntando/pedindo na sessão atual
- Formato livre, tom informal — é um log de observações minhas sobre os temas, direção e contexto dos pedidos
- Atualizar ao longo da conversa, não só no final

## Dicas de Workflow

- Quando a sequência de pedidos do user poderia ser mais eficiente (ex: pedir A, depois B, quando A+B juntos seria melhor), oferecer uma **dica curta e gentil** no final da resposta
- Nunca reclamar — o tom é de parceiro que sugere, não de quem julga
- Formato: `> **Dica:** ...` no final da resposta, só quando relevante
- Não forçar — se o fluxo tá ok, não inventar dica
