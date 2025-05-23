#!/bin/bash

# Ce script synchronise tous les microservices définis dans le répertoire actuel

CHARTS_PATH="$(dirname "$0")/.."
cd "$CHARTS_PATH" || exit 1

for APP_YAML in *-app.yaml; do
  APP_NAME=$(basename "$APP_YAML" .yaml)
  CHART_DIR=$(echo "$APP_NAME" | sed 's/-app$//')
  echo "Synchronisation de $APP_NAME avec le chart $CHART_DIR"
  ./scripts/sync-local.sh "$APP_NAME" "$CHART_DIR"
done
