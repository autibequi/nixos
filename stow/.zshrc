# Created by newuser for 5.9

# pnpm
export PNPM_HOME="/home/pedrinho/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Leech CLI
export PATH="/home/pedrinho/nixos/stow/.local/bin:$PATH"
alias zion=leech
alias claudio=leech

# Dynamic completions (always in sync with CLI)
eval "$(leech completions zsh)"
compdef zion=leech
