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

# Pacotes base — sem IDE/agentes (esses vão nas imagens filhas)
RUN --mount=type=cache,target=/root/.cache/nix \
    nix profile install \
    nixpkgs#jq \
    nixpkgs#python3 \
    nixpkgs#wl-clipboard \
    nixpkgs#sox \
    nixpkgs#util-linux \
    nixpkgs#systemdMinimal \
    nixpkgs#gh \
    nixpkgs#gawk \
    nixpkgs#gnused \
    nixpkgs#espeak-ng \
    nixpkgs#coreutils \
    nixpkgs#gosu \
    nixpkgs#docker-client \
    nixpkgs#yt-dlp

# User claude (UID/GID ajustáveis via entrypoint)
RUN echo "claude:x:1000:1000::/home/claude:/bin/bash" >> /etc/passwd && \
    echo "claude:x:1000:" >> /etc/group && \
    echo "systemd-journal:x:190:claude" >> /etc/group && \
    mkdir -p /home/claude/.claude /home/claude/.local/bin /home/claude/.config && \
    cp -r /root/.nix-profile /home/claude/.nix-profile && \
    chown -R 1000:1000 /home/claude && \
    ln -sf /root/.nix-profile/bin/bash /bin/bash

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
