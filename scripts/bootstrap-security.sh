#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ -f "${ENV_FILE}" ]] && grep -q '^APISIX_JWT_SECRET=' "${ENV_FILE}"; then
  echo "La configuración JWT local ya existe en ${ENV_FILE}."
  exit 0
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl es requerido para generar el secreto local." >&2
  exit 1
fi

SECRET="$(openssl rand -hex 32)"
umask 077

touch "${ENV_FILE}"
printf '\nAPISIX_JWT_SECRET=%s\n' "${SECRET}" >> "${ENV_FILE}"

echo "Se generó APISIX_JWT_SECRET en ${ENV_FILE}."
echo "El archivo queda fuera de Git y se usa únicamente para el entorno local."
