# syntax=docker/dockerfile:1
FROM node:14-alpine

RUN apk add --no-cache git ca-certificates python3 make g++

WORKDIR /app

EXPOSE 9090

# 0.0.0.0 para aceitar conexoes externas ao container
ENV LOCAL_BO_CONTAINER_HOST=0.0.0.0

# node_modules vem do bind mount (gerado por: zion docker install bo-container)
# Roda quasar dev diretamente — vars vem do Docker env_file, nao do env-cmd
CMD ["./node_modules/.bin/quasar", "dev"]
