# syntax=docker/dockerfile:1
FROM node:14-alpine

RUN apk add --no-cache git openssh-client ca-certificates python3 make g++

WORKDIR /app

EXPOSE 9090

# 0.0.0.0 para aceitar conexoes externas ao container
ENV LOCAL_BO_CONTAINER_HOST=0.0.0.0

# node_modules vem do bind mount (gerado por: coruja install)
# node-sass precisa ser recompilado para musl (Alpine) se instalado em glibc
#
# O bo roda Vite via env-cmd: `npm run serve:<env>` (= env-cmd -e <env> -- vite),
# onde <env> ∈ local|sandbox|qa|prod seleciona o bloco do .env-cmdrc.js (muda as
# API_*_URL). BO_ENV vem do compose; `--host 0.0.0.0` força o vite a escutar em
# todas as interfaces — o bloco do .env-cmdrc.js sobrescreve LOCAL_BO_CONTAINER_HOST
# com um hostname, então o flag de CLI (que tem precedência) garante o bind certo.
CMD ["sh", "-c", "npm run serve:${BO_ENV:-local} -- --host 0.0.0.0"]
