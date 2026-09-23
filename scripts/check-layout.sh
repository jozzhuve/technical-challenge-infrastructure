#!/usr/bin/env sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

for repo in technical-challenge-endorsement technical-challenge-routing technical-challenge-web technical-challenge-infrastructure; do
  if [ ! -d "$ROOT_DIR/$repo" ]; then
    echo "Falta el repositorio $repo dentro de $ROOT_DIR"
    exit 1
  fi
done

echo "Estructura local correcta. Los cuatro repositorios están disponibles."
