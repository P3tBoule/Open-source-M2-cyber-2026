#!/bin/bash
# Script pour générer les certificats Wazuh
# Exécuter ceci avant le déploiement si les certificats n'existent pas

set -e

WORK_DIR="/opt/secure-app"
CERTS_DIR="$WORK_DIR/wazuh/wazuh_indexer_ssl_certs"

echo "Génération des certificats Wazuh..."

# Créer les répertoires
mkdir -p "$CERTS_DIR/certs"
mkdir -p "$WORK_DIR/wazuh/api_certs"

# Télécharger et exécuter le script de génération de certificats de Wazuh
docker run --rm \
  -v "$CERTS_DIR:/certs_output" \
  -e CERTIFICATE_AUTHORITIES=true \
  -e RA_SERVER=true \
  -e ELASTICSEARCH=true \
  -e CREATE_API_CERTS=true \
  wazuh/wazuh:latest \
  bash -c '/usr/share/wazuh/certs/certs_generator.sh' || true

echo "Certificats générés dans $CERTS_DIR"
chmod -R 755 "$CERTS_DIR"
chmod -R 755 "$WORK_DIR/wazuh/api_certs"
