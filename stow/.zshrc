# Created by newuser for 5.9

# pnpm
export PNPM_HOME="/home/pedrinho/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# export BARDIEL_PATH="$HOME/projects/pessoal/bardiel"
