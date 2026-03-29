# vennon-claude — herda de vennon-vennon + instala claude-code
# Build: podman build -t vennon-claude containers/claude/
FROM vennon-vennon:latest

# Claude Code via nix flake
RUN --mount=type=cache,target=/root/.cache/nix \
    nix profile install github:sadjow/claude-code-nix && \
    cp -r /root/.nix-profile /home/claude/.nix-profile && \
    chown -R 1000:1000 /home/claude/.nix-profile
