# syntax=docker/dockerfile:1
FROM node:14-alpine

RUN apk add --no-cache git ca-certificates python3 make g++

WORKDIR /app

EXPOSE 8082

# 0.0.0.0 para aceitar conexoes externas ao container
ENV HOST=0.0.0.0
ENV PORT=8082

# node_modules vem do bind mount (gerado por: zion docker install front-student)
# Roda nuxt dev diretamente — vars vem do Docker env_file
CMD ["./node_modules/.bin/nuxt", "dev"]
