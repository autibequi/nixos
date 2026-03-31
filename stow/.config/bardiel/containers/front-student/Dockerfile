# syntax=docker/dockerfile:1
FROM oven/bun:alpine AS bun-bin

FROM node:20-alpine

# bash — vennon exec/shell usa `podman exec … /bin/bash -c` (ver service.rs)
RUN apk add --no-cache bash git ca-certificates python3 make g++ \
    autoconf automake libtool nasm pkgconfig

# Gambiarra experimental: bun como runtime no lugar do node
COPY --from=bun-bin /usr/local/bin/bun /usr/local/bin/bun
RUN ln -sf /usr/local/bin/bun /usr/local/bin/node

WORKDIR /app

EXPOSE 3005

# 0.0.0.0 para aceitar conexoes externas ao container
ENV HOST=0.0.0.0

# Wrapper: imprime tempo decorrido a cada 20s enquanto o webpack builda
RUN <<'EOF' tee /usr/local/bin/progress-wrap
#!/bin/sh
START=$(date +%s)
heartbeat() {
  while true; do
    sleep 20
    E=$(( $(date +%s) - START ))
    MIN=$(( E / 60 ))
    SEC=$(( E % 60 ))
    printf "[front-student] buildando... %dm%ds\n" "$MIN" "$SEC"
  done
}
heartbeat &
HB=$!
"$@"
CODE=$?
kill $HB 2>/dev/null
E=$(( $(date +%s) - START ))
MIN=$(( E / 60 ))
SEC=$(( E % 60 ))
printf "[front-student] pronto em %dm%ds (exit %s)\n" "$MIN" "$SEC" "$CODE"
exit $CODE
EOF
RUN chmod +x /usr/local/bin/progress-wrap

# node_modules vem do bind mount (gerado por: vennon docker install front-student)
# Comando: npm run <NPM_SCRIPT_ENV>:<VERTICAL> (ex: npm run dev:carreiras-juridicas)
# NPM_SCRIPT_ENV e VERTICAL vem do docker-compose environment
CMD ["sh", "-c", "progress-wrap npm run ${NPM_SCRIPT_ENV:-dev}:${VERTICAL:-carreiras-juridicas}"]
