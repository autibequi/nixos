# syntax=docker/dockerfile:1
# vennon-leech — imagem base com nix + tools (SEM claude-code/opencode/cursor)
# Build: podman build -t vennon-leech containers/leech/

# Stage 0: Cursor CLI (FHS — reutilizado por vennon-cursor no futuro)
FROM debian:bookworm-slim AS cursor-cli
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -fsSL https://cursor.com/install | bash && \
    rm -rf /var/lib/apt/lists/*

# Stage 1: Nix + ferramentas base
FROM nixos/nix:latest

RUN mkdir -p /etc/nix && \
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

# Pacotes base — separados em 2 layers para cache eficiente
# Layer 1: core tools (muda raramente)
RUN nix profile install \
    nixpkgs#coreutils \
    nixpkgs#gnused \
    nixpkgs#gawk \
    nixpkgs#jq \
    nixpkgs#util-linux \
    nixpkgs#gosu \
    nixpkgs#docker-client \
    nixpkgs#gh

# Layer 2: extras (muda mais)
RUN nix profile install \
    nixpkgs#python3 \
    nixpkgs#wl-clipboard \
    nixpkgs#sox \
    nixpkgs#systemdMinimal \
    nixpkgs#espeak-ng \
    nixpkgs#yt-dlp

# Layer 3: shell (zsh + powerlevel10k)
RUN nix profile install \
    nixpkgs#zsh \
    nixpkgs#zsh-powerlevel10k \
    nixpkgs#zsh-autosuggestions \
    nixpkgs#zsh-syntax-highlighting \
    nixpkgs#fzf \
    nixpkgs#eza \
    nixpkgs#bat \
    nixpkgs#ripgrep \
    nixpkgs#fd

# User claude (UID/GID ajustáveis via entrypoint)
RUN echo "claude:x:1000:1000::/home/claude:/bin/zsh" >> /etc/passwd && \
    echo "claude:x:1000:" >> /etc/group && \
    echo "systemd-journal:x:190:claude" >> /etc/group && \
    mkdir -p /home/claude/.claude /home/claude/.local/bin /home/claude/.config /home/claude/.cache && \
    cp -r /root/.nix-profile /home/claude/.nix-profile && \
    chown -R 1000:1000 /home/claude && \
    ln -sf /root/.nix-profile/bin/bash /bin/bash && \
    ln -sf /root/.nix-profile/bin/zsh /bin/zsh

# Zsh config with powerlevel10k
RUN ZSH_PLUGINS="/home/claude/.nix-profile/share" && \
    echo '# Powerlevel10k instant prompt' > /home/claude/.zshrc && \
    echo 'if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then' >> /home/claude/.zshrc && \
    echo '  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"' >> /home/claude/.zshrc && \
    echo 'fi' >> /home/claude/.zshrc && \
    echo '' >> /home/claude/.zshrc && \
    echo 'source '"$ZSH_PLUGINS"'/zsh-powerlevel10k/powerlevel10k.zsh-theme' >> /home/claude/.zshrc && \
    echo 'source '"$ZSH_PLUGINS"'/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /home/claude/.zshrc && \
    echo 'source '"$ZSH_PLUGINS"'/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /home/claude/.zshrc && \
    echo '' >> /home/claude/.zshrc && \
    echo 'alias ls="eza --icons"' >> /home/claude/.zshrc && \
    echo 'alias ll="eza -la --icons"' >> /home/claude/.zshrc && \
    echo 'alias cat="bat --plain"' >> /home/claude/.zshrc && \
    echo 'alias grep="rg"' >> /home/claude/.zshrc && \
    echo 'alias find="fd"' >> /home/claude/.zshrc && \
    echo '' >> /home/claude/.zshrc && \
    echo 'export HISTSIZE=10000' >> /home/claude/.zshrc && \
    echo 'export SAVEHIST=10000' >> /home/claude/.zshrc && \
    echo 'export HISTFILE=~/.zsh_history' >> /home/claude/.zshrc && \
    echo 'setopt SHARE_HISTORY' >> /home/claude/.zshrc && \
    echo '[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh' >> /home/claude/.zshrc && \
    chown 1000:1000 /home/claude/.zshrc

# Cursor CLI + FHS libs (para futuro vennon-cursor)
RUN mkdir -p /home/claude/.local/share /lib64 /lib/x86_64-linux-gnu
COPY --from=cursor-cli /root/.local/bin/ /home/claude/.local/bin/
COPY --from=cursor-cli /root/.local/share/ /home/claude/.local/share/
COPY --from=cursor-cli /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /lib64/
COPY --from=cursor-cli /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/
COPY --from=cursor-cli /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/
RUN CURSOR_VER="$(ls /home/claude/.local/share/cursor-agent/versions)" && \
    rm -f /home/claude/.local/bin/agent /home/claude/.local/bin/cursor-agent && \
    ln -s /home/claude/.local/share/cursor-agent/versions/"$CURSOR_VER"/cursor-agent /home/claude/.local/bin/agent && \
    ln -s /home/claude/.local/share/cursor-agent/versions/"$CURSOR_VER"/cursor-agent /home/claude/.local/bin/cursor-agent && \
    chown -R 1000:1000 /home/claude/.local

# mcp-grafana
RUN curl -fsSL "https://github.com/grafana/mcp-grafana/releases/latest/download/mcp-grafana_Linux_x86_64.tar.gz" \
    | tar xz -C /home/claude/.local/bin/ mcp-grafana && \
    chown 1000:1000 /home/claude/.local/bin/mcp-grafana

RUN mkdir -p /workspace && chown 1000:1000 /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PATH="/home/claude/.local/bin:/home/claude/.nix-profile/bin:/root/.nix-profile/bin:/usr/bin:/bin:${PATH}"
ENV HOME=/home/claude

ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /workspace
