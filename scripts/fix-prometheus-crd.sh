#!/bin/bash

# Script de correction pour Prometheus dans le cluster EKS
# Auteur: Arsenii TOLMACHEV
# Date: 24 mai 2025

set -e

echo "=== Diagnostic et correction de Prometheus ==="

# Vérification du namespace monitoring
echo "1. Vérification du namespace monitoring..."
kubectl get namespace monitoring || kubectl create namespace monitoring

# Vérification des CRDs Prometheus
echo "2. Vérification des CRDs Prometheus..."
if ! kubectl get crd prometheuses.monitoring.coreos.com >/dev/null 2>&1; then
    echo "Installation des CRDs Prometheus..."
    kubectl create -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
    kubectl create -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
    kubectl create -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
fi

# Vérification des services
echo "3. Vérification des services Prometheus..."
kubectl get svc -n monitoring

# Vérification des pods
echo "4. Vérification des pods Prometheus..."
kubectl get pods -n monitoring

# Test de connectivité
echo "5. Test de connectivité..."
PROMETHEUS_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "$PROMETHEUS_POD" ]; then
    echo "Pod Prometheus trouvé: $PROMETHEUS_POD"
    echo "Test de port-forward..."
    timeout 10s kubectl port-forward pod/$PROMETHEUS_POD -n monitoring 9090:9090 &
    PF_PID=$!
    sleep 3
    
    if curl -s http://localhost:9090 >/dev/null 2>&1; then
        echo "✅ Prometheus accessible via port-forward"
    else
        echo "❌ Prometheus non accessible"
    fi
    
    kill $PF_PID 2>/dev/null || true
else
    echo "❌ Aucun pod Prometheus trouvé"
fi

echo "=== Diagnostic terminé ==="

# Instructions pour l'utilisateur
cat << EOF

Instructions de dépannage:

1. Pour accéder à Prometheus:
   kubectl port-forward svc/prometheus-prometheus -n monitoring 9090:9090

2. Si le port-forward échoue, essayez:
   kubectl port-forward pod/\$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}') -n monitoring 9090:9090

3. Pour réinstaller Prometheus:
   argocd app delete prometheus --cascade
   argocd app create -f monitoring/prometheus-app.yaml
   argocd app sync prometheus --force

4. URL d'accès: http://localhost:9090

EOF