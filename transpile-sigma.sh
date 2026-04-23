#!/bin/bash
# Script pour transpiler les règles Sigma vers le format Wazuh

# Vérifier si sigma-cli est installé
if ! command -v sigma &> /dev/null; then
    echo "Installation de sigma-cli..."
    pip3 install sigma-cli
fi

# Créer le répertoire de sortie
mkdir -p sigma-output

# Transpiler les règles Sigma vers différents formats
echo "Transpilation des règles Sigma..."

# Format Wazuh
sigma rule sigma/detection_rules.yaml \
    --output-format wazuh \
    --output-file sigma-output/wazuh_rules.txt \
    2>/dev/null || echo "Format Wazuh non supporté par sigma-cli"

# Format Elastic/Kibana
sigma rule sigma/detection_rules.yaml \
    --output-format elasticquery \
    --output-file sigma-output/elastic_rules.txt \
    2>/dev/null || echo "Format Elastic non supporté"

# Format Splunk
sigma rule sigma/detection_rules.yaml \
    --output-format splunk \
    --output-file sigma-output/splunk_rules.txt \
    2>/dev/null || echo "Format Splunk non supporté"

# Format ArcSight
sigma rule sigma/detection_rules.yaml \
    --output-format arcsight \
    --output-file sigma-output/arcsight_rules.txt \
    2>/dev/null || echo "Format ArcSight non supporté"

# Format generic (processus texte standard)
sigma rule sigma/detection_rules.yaml \
    --output-format generic \
    --output-file sigma-output/generic_rules.txt \
    2>/dev/null || true

echo "Règles Sigma transpilées:"
ls -la sigma-output/

echo ""
echo "Les règles transpilées peuvent être utilisées dans:"
echo "- Wazuh: Copier les règles dans /var/ossec/etc/rules/"
echo "- Elastic/Kibana: Importer via l'interface de gestion des règles"
echo "- Splunk: Utiliser via les recherches sauvegardées"
echo "- ArcSight: Importer dans le gestionnaire d'événements"
