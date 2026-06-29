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

alias momoko="yaa --joy"

# n — upgrade do NixOS pelo Makefile do repo ~/nixos, de QUALQUER pasta.
#   n              → make -C ~/nixos upgrade
#   n FOO=bar      → make -C ~/nixos upgrade FOO=bar
n() {
  make -C ~/nixos upgrade "$@"
}

# --- clipboard helpers (Wayland / wl-clipboard) ---
# cl <cmd...>   → roda o comando, mostra na tela E copia o output (stdout+stderr, sem ANSI) pro clipboard
#                 ex: cl systemctl is-enabled suspend.target
# <cmd> | clip  → copia o que vier no pipe (ex: cat arquivo | clip)
clip() { wl-copy; }
cl() {
  local out
  out="$("$@" 2>&1)"
  print -r -- "$out"
  printf '%s' "$out" | wl-copy
}
