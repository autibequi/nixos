# syntax=docker/dockerfile:1
FROM node:20-alpine

# bash — bardiel plug shell usa `podman exec … /bin/bash -c`
RUN apk add --no-cache bash git ca-certificates python3 make g++ \
    autoconf automake libtool nasm pkgconfig unzip \
    && npm install -g bun

WORKDIR /app

EXPOSE 3005

# 0.0.0.0 para aceitar conexoes externas ao container
ENV HOST=0.0.0.0

# Wrapper: imprime tempo decorrido a cada 20s — "buildando" até 2min, "rodando" depois
RUN <<'EOF' tee /usr/local/bin/progress-wrap
#!/bin/sh
START=$(date +%s)
BUILD_TIMEOUT=120
heartbeat() {
  while true; do
    sleep 20
    E=$(( $(date +%s) - START ))
    MIN=$(( E / 60 ))
    SEC=$(( E % 60 ))
    if [ $E -lt $BUILD_TIMEOUT ]; then
      printf "[front-student] buildando... %dm%ds\n" "$MIN" "$SEC"
    else
      printf "[front-student] rodando... %dm%ds\n" "$MIN" "$SEC"
    fi
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

# node_modules vem do bind mount (gerado por: bardiel plug front-student install)
# Comando: npm run <NPM_SCRIPT_ENV>:<VERTICAL> (ex: npm run local:carreiras-juridicas)
# NPM_SCRIPT_ENV e VERTICAL vêm do docker-compose environment (package.json usa local:* / devbox:* / sandbox:*…)
CMD ["sh", "-c", "progress-wrap npm run ${NPM_SCRIPT_ENV:-local}:${VERTICAL:-carreiras-juridicas}"]
