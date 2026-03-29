# syntax=docker/dockerfile:1
FROM node:20-alpine

RUN apk add --no-cache git ca-certificates python3 make g++ \
    autoconf automake libtool nasm pkgconfig

WORKDIR /app

EXPOSE 3005

# 0.0.0.0 para aceitar conexoes externas ao container
ENV HOST=0.0.0.0

# node_modules vem do bind mount (gerado por: vennon docker install front-student)
# Comando: npm run <NPM_SCRIPT_ENV>:<VERTICAL> (ex: npm run dev:carreiras-juridicas)
# NPM_SCRIPT_ENV e VERTICAL vem do docker-compose environment
CMD ["sh", "-c", "npm run ${NPM_SCRIPT_ENV:-dev}:${VERTICAL:-carreiras-juridicas}"]
