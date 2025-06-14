# Plano de Implementação: Função de Repetição de Comando com nix-shell

## 1. Estado Atual do Código
- Temos um arquivo `init.sh` com algumas funções utilitárias
- O problema ocorre quando tentamos executar comandos que não estão no PATH
- O sistema sugere usar `nix-shell -p <package>` para resolver

## 2. O que Deve Mudar
- Precisamos criar uma função que:
  - Capture o último comando executado
  - Extraia o nome do pacote necessário
  - Execute o comando dentro de um nix-shell com o pacote necessário
  - Mantenha o histórico de comandos

## 3. O que Será Feito
1. Criar uma função chamada `repeat_with_nix`
2. A função irá:
   - Usar `fc -ln -1` para obter o último comando
   - Extrair o nome do pacote da mensagem de erro
   - Executar o comando original dentro de nix-shell
3. Adicionar a função ao arquivo `init.sh`
4. Testar a implementação

## Dependências
- Bash
- nix-shell
- fc (built-in do bash)

## Observações
- A função deve ser robusta para lidar com diferentes formatos de erro
- Deve manter o histórico de comandos do shell
- Deve ser fácil de usar e intuitiva