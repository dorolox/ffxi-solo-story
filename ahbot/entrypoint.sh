#!/bin/sh
# Génère config.yaml depuis l'environnement (mot de passe DB jamais versionné), puis lance ffxiahbot.
set -e
umask 077
cat > /tmp/config.yaml <<CFG
name: "${AHBOT_NAME:-Marchand}"
tick: ${AHBOT_TICK:-30}
restock: ${AHBOT_RESTOCK:-3600}
use_buying_rates: false
use_selling_rates: false
hostname: "${AHBOT_DB_HOST:-database}"
database: "${MARIADB_DATABASE}"
username: "${MARIADB_USER}"
password: "${MARIADB_PASSWORD}"
port: ${AHBOT_DB_PORT:-3306}
fail: true
CFG
cmd="$1"; shift
exec ffxiahbot "$cmd" --config /tmp/config.yaml --inp-csv /work/items.csv "$@"
