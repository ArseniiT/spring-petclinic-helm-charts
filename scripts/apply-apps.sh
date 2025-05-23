#!/bin/bash

# === Script pour appliquer tous les fichiers Application ArgoCD ===

CHARTS_PATH="$(dirname "$0")/.."

echo "Déploiement des applications ArgoCD depuis : $CHARTS_PATH"

for APP_MANIFEST in "$CHARTS_PATH"/*-app.yaml; do
  echo "Application du fichier : $APP_MANIFEST"
  kubectl apply -f "$APP_MANIFEST" -n argocd
done

echo "Toutes les applications ont été appliquées avec succès."
