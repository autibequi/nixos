# syntax=docker/dockerfile:1
FROM node:14-alpine

RUN apk add --no-cache git openssh-client ca-certificates python3 make g++

WORKDIR /app

# Copiar apenas arquivos de dependencias primeiro (cache layer)
COPY package.json package-lock.json .npmrc ./

# Instalar dependencias:
#   --mount=type=ssh  → git+ssh para frontend-libs (requer SSH agent no host)
#   NPM_TOKEN         → autenticacao no GitHub Package Registry (@estrategiahq/*)
ARG NPM_TOKEN
RUN --mount=type=ssh \
    mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts 2>/dev/null && \
    if [ -n "$NPM_TOKEN" ]; then \
      echo "//npm.pkg.github.com/:_authToken=${NPM_TOKEN}" >> .npmrc; \
    fi && \
    npm install && \
    sed -i '/_authToken/d' .npmrc || true

# Copiar source (node_modules fica na layer anterior — nao e sobrescrito)
COPY . .

EXPOSE 9090

# 0.0.0.0 para aceitar conexoes externas ao container
ENV LOCAL_BO_CONTAINER_HOST=0.0.0.0

# Roda quasar dev diretamente — vars vem do Docker env_file, nao do env-cmd
CMD ["./node_modules/.bin/quasar", "dev"]
