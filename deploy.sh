#!/bin/bash
# Script de déploiement simplifié sans Ansible
# À utiliser si Ansible n'est pas disponible

set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Déploiement Sécurisé d'Application 3-Tiers ===${NC}"

# Vérifier que nous sommes en root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Ce script doit être exécuté en root (sudo)${NC}"
    exit 1
fi

APP_PATH="/opt/secure-app"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}[1/5] Installation des prérequis...${NC}"

# Mettre à jour le système
apt-get update
apt-get install -y \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    jq \
    htop \
    net-tools \
    vim \
    unzip

echo -e "${GREEN}✓ Prérequis installés${NC}"

echo -e "${BLUE}[2/5] Installation de Docker...${NC}"

# Ajouter la clé GPG et le repo Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Démarrer Docker
systemctl start docker
systemctl enable docker

echo -e "${GREEN}✓ Docker installé$(docker --version)${NC}"

echo -e "${BLUE}[3/5] Installation de Docker Compose...${NC}"

# Installer Docker Compose
DOCKER_COMPOSE_VERSION="v2.20.0"
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

echo -e "${GREEN}✓ Docker Compose installé: $(docker-compose --version)${NC}"

echo -e "${BLUE}[4/5] Clonage et configuration de l'application...${NC}"

# Créer le répertoire d'application
mkdir -p "$APP_PATH"
cd "$APP_PATH"

# Cloner l'application
if [ ! -d "app/.git" ]; then
    echo "Clonage du dépôt..."
    git clone https://github.com/ynov-cd/Open-source-M2-cyber-2026 app
fi

# Copier les fichiers de configuration depuis le script
cp "$SCRIPT_DIR/Dockerfile.backend" .
cp "$SCRIPT_DIR/Dockerfile.frontend" .
cp "$SCRIPT_DIR/nginx.conf" .
cp "$SCRIPT_DIR/docker-compose.yml" .
cp "$SCRIPT_DIR/docker-compose.security.yml" .
cp "$SCRIPT_DIR/.env" .

# Créer les répertoires de configuration
mkdir -p traefik falco suricata/rules wazuh/rules yara sigma shuffle database/pgdata

# Copier les fichiers de config
cp "$SCRIPT_DIR/falco/falco.yaml" falco/
cp "$SCRIPT_DIR/falco/falco-rules.yaml" falco/
cp "$SCRIPT_DIR/suricata/suricata.yaml" suricata/
cp "$SCRIPT_DIR/suricata/custom-rules.rules" suricata/rules/
cp "$SCRIPT_DIR/wazuh/rules/custom_rules.xml" wazuh/rules/
cp "$SCRIPT_DIR/yara/nodejs_malware.yar" yara/
cp "$SCRIPT_DIR/sigma/detection_rules.yaml" sigma/
cp "$SCRIPT_DIR/shuffle/wazuh-alert-workflow.json" shuffle/

# Permissions appropriées
chmod 600 .env
chmod 755 database/pgdata

echo -e "${GREEN}✓ Application configurée${NC}"

echo -e "${BLUE}[5/5] Lancement des conteneurs...${NC}"

# Build et lancer les conteneurs
docker-compose build --no-cache
docker-compose up -d

# Attendre que les services soient prêts
echo "Attente du démarrage des services (30 secondes)..."
sleep 30

# Vérifier le statut
docker-compose ps

echo -e "${GREEN}✓ Conteneurs lancés${NC}"

# Lancer la stack de sécurité
echo -e "${BLUE}Lancement de la stack de sécurité...${NC}"
docker-compose -f docker-compose.security.yml up -d

echo "Attente du démarrage de la stack sécurité (60 secondes)..."
sleep 60

docker-compose -f docker-compose.security.yml ps

echo ""
echo -e "${GREEN}=== Déploiement Complété ===${NC}"
echo ""
echo "Application accessible sur:"
echo -e "  ${BLUE}Frontend:${NC} http://localhost/"
echo -e "  ${BLUE}API:${NC} http://localhost/api/"
echo -e "  ${BLUE}Traefik Dashboard:${NC} http://localhost:8080"
echo ""
echo "Stack de Sécurité:"
echo -e "  ${BLUE}Wazuh Dashboard:${NC} https://localhost:443 (admin/admin)"
echo -e "  ${BLUE}Shuffle:${NC} http://localhost:3001"
echo ""
echo "Répertoire d'application: $APP_PATH"
echo ""
echo "Commandes utiles:"
echo "  docker-compose ps"
echo "  docker-compose logs -f"
echo "  docker-compose -f docker-compose.security.yml logs -f falco"
echo ""
