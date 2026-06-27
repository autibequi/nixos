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

# n — nixos-rebuild switch do flake ~/nixos, de QUALQUER pasta. Flags como args:
#   n              → nh os switch ~/nixos
#   n --update     → atualiza o flake.lock e aplica
# Filtra o ruído de "• Added/Updated/Removed input" do lock diff (mantém erros/warnings).
n() {
  setopt local_options pipefail
  nh os switch ~/nixos "$@" 2>&1 | grep -vaE '(Added|Updated|Removed) input|narHash=|^[[:space:]]*follows .|^[[:space:]]*\(20[0-9][0-9]-'
}
