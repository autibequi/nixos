# syntax=docker/dockerfile:1
FROM node:20-alpine

# bash — vennon exec/shell usa `podman exec … /bin/bash -c` (ver service.rs)
RUN apk add --no-cache bash git ca-certificates python3 make g++ \
    autoconf automake libtool nasm pkgconfig

WORKDIR /app

EXPOSE 3005

# 0.0.0.0 para aceitar conexoes externas ao container
ENV HOST=0.0.0.0

# Wrapper: imprime tempo decorrido a cada 20s enquanto o webpack builda
RUN printf '#!/bin/sh\nSTART=$(date +%s)\nheartbeat() {\n  while true; do\n    sleep 20\n    E=$(( $(date +%s) - START ))\n    printf "[front-student] buildando... %dm%ds\\n" $(( E/60 )) $(( E%%60 ))\n  done\n}\nheartbeat &\nHB=$!\n"$@"\nCODE=$?\nkill $HB 2>/dev/null\nE=$(( $(date +%s) - START ))\nprintf "[front-student] pronto em %dm%ds (exit %s)\\n" $(( E/60 )) $(( E%%60 )) $CODE\nexit $CODE\n' > /usr/local/bin/progress-wrap && chmod +x /usr/local/bin/progress-wrap

# node_modules vem do bind mount (gerado por: vennon docker install front-student)
# Comando: npm run <NPM_SCRIPT_ENV>:<VERTICAL> (ex: npm run dev:carreiras-juridicas)
# NPM_SCRIPT_ENV e VERTICAL vem do docker-compose environment
CMD ["sh", "-c", "progress-wrap npm run ${NPM_SCRIPT_ENV:-dev}:${VERTICAL:-carreiras-juridicas}"]
