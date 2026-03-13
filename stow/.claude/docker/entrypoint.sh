#!/bin/sh
# Configure git to use SSH instead of HTTPS for private GitHub repos
git config --global url."git@github.com:estrategiahq/".insteadOf "https://github.com/estrategiahq/"

exec "$@"
