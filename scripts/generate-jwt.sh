#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
JWT_KEY="${APISIX_JWT_KEY:-challenge-web}"
TTL_SECONDS="${JWT_TTL_SECONDS:-3600}"

if [[ -z "${APISIX_JWT_SECRET:-}" ]] && [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

if [[ -z "${APISIX_JWT_SECRET:-}" ]]; then
  echo "No se encontró APISIX_JWT_SECRET. Ejecuta ./scripts/bootstrap-security.sh primero." >&2
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl es requerido para firmar el JWT." >&2
  exit 1
fi

base64url() {
  openssl base64 -A | tr '+/' '-_' | tr -d '='
}

NOW="$(date +%s)"
EXP="$((NOW + TTL_SECONDS))"
HEADER="$(printf '%s' '{"alg":"HS256","typ":"JWT"}' | base64url)"
PAYLOAD="$(printf '{"key":"%s","iat":%s,"exp":%s}' "${JWT_KEY}" "${NOW}" "${EXP}" | base64url)"
UNSIGNED_TOKEN="${HEADER}.${PAYLOAD}"
SIGNATURE="$(printf '%s' "${UNSIGNED_TOKEN}" | openssl dgst -sha256 -hmac "${APISIX_JWT_SECRET}" -binary | base64url)"

printf '%s\n' "${UNSIGNED_TOKEN}.${SIGNATURE}"
