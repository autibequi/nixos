# syntax=docker/dockerfile:1
FROM node:14-alpine

RUN apk add --no-cache git ca-certificates python3 make g++

WORKDIR /app

EXPOSE 8082

# 0.0.0.0 para aceitar conexoes externas ao container
ENV HOST=0.0.0.0
ENV PORT=8082

# node_modules vem do bind mount (gerado por: zion docker install front-student)
# Comando: npm run <VERTICAL>:<APP_ENV> (ex: npm run carreiras-juridicas:sand)
# VERTICAL e APP_ENV vem do docker-compose environment
CMD ["sh", "-c", "npm run ${VERTICAL:-carreiras-juridicas}:${APP_ENV:-sand}"]
