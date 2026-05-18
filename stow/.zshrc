# Created by newuser for 5.9

# pnpm
export PNPM_HOME="/home/pedrinho/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# export BARDIEL_PATH="$HOME/projects/pessoal/bardiel"

# Terminal title: comando rodando ou diretório atual
preexec() { print -Pn "\e]0;${1%% *}\a" }   # nome do comando (ex: vim, go, npm)
precmd()  { print -Pn "\e]0;%1~\a" }         # último componente do cwd (ex: coruja, ~)
