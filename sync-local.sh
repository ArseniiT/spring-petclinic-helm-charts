#!/bin/bash

# example d'utilisation :
# ./sync-local.sh api-gateway-app api-gateway

APP_NAME=$1
CHART_DIR=$2

if [ -z "$APP_NAME" ] || [ -z "$CHART_DIR" ]; then
  echo "Usage : $0 <app-name> <chart-directory>"
  exit 1
fi

VALUES_FILE="$CHART_DIR/values.yaml"
SECRET_VALUES_FILE="$CHART_DIR/values.secret.yaml"
BACKUP_FILE="$CHART_DIR/values.yaml.bak"

# Vérification
if [ ! -f "$VALUES_FILE" ]; then
  echo " $VALUES_FILE non trouvé"
  exit 1
fi
if [ ! -f "$SECRET_VALUES_FILE" ]; then
  echo " $SECRET_VALUES_FILE non trouvé"
  exit 1
fi
if ! command -v yq >/dev/null 2>&1; then
  echo " yq non installé. Installe-le avec : sudo snap install yq"
  exit 1
fi

# Sauvegarde
cp "$VALUES_FILE" "$BACKUP_FILE"

# Fusion
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$BACKUP_FILE" "$SECRET_VALUES_FILE" > "$VALUES_FILE"

# Synchronisation
echo " Synchronisation locale de $APP_NAME..."
argocd app sync "$APP_NAME" --local "$CHART_DIR" --prune --force

# Restauration
mv "$BACKUP_FILE" "$VALUES_FILE"
