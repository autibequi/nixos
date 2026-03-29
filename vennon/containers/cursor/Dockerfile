# syntax=docker/dockerfile:1
# vennon-cursor — herda vennon-vennon e instala apenas Cursor CLI (glibc/FHS do Debian).
FROM debian:bookworm-slim AS cursor-cli
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -fsSL https://cursor.com/install | bash && \
    rm -rf /var/lib/apt/lists/*

FROM vennon-vennon:latest

USER root
RUN mkdir -p /home/claude/.local/share /lib64 /lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
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

RUN test -x /home/claude/.local/bin/cursor-agent
