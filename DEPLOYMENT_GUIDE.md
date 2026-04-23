# GUIDE COMPLET DE DÉPLOIEMENT

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Installation Rapide](#installation-rapide)
3. [Déploiement avec Ansible](#déploiement-avec-ansible)
4. [Déploiement Manuel](#déploiement-manuel)
5. [Vérification du Déploiement](#vérification-du-déploiement)
6. [Accès aux Services](#accès-aux-services)
7. [Tests de Sécurité](#tests-de-sécurité)
8. [Troubleshooting](#troubleshooting)

---

## Prérequis

### Matériel
- **RAM**: Minimum 16GB (la stack sécurité est gourmande)
- **Disque**: 50GB d'espace libre
- **CPU**: 4 cores recommandé
- **OS**: Linux (Ubuntu 20.04+ ou Debian 11+)

### Logiciels
- Git
- Docker & Docker Compose
- Ansible (optionnel, pour déploiement automatisé)
- Python 3.8+

---

## Installation Rapide

### Option 1 : Avec Ansible (Recommandé)

```bash
# 1. Cloner le dépôt
git clone <votre-repo> secure-deployment
cd secure-deployment

# 2. Installer Ansible
sudo apt-get update
sudo apt-get install -y ansible

# 3. Lancer le déploiement
sudo ansible-playbook deploy.yml -i inventory.ini

# 4. Attendre 30-40 minutes
```

### Option 2 : Script Bash

```bash
# 1. Cloner le dépôt
git clone <votre-repo> secure-deployment
cd secure-deployment

# 2. Lancer le script
sudo bash deploy.sh

# 3. Attendre la fin du déploiement
```

### Option 3 : Manuel

```bash
# 1. Cloner le dépôt et application
git clone <votre-repo> secure-deployment
cd secure-deployment
git clone https://github.com/ynov-cd/Open-source-M2-cyber-2026 app

# 2. Construire et lancer
docker-compose build
docker-compose up -d

# 3. Attendre 30 secondes
sleep 30

# 4. Lancer la stack sécurité
docker-compose -f docker-compose.security.yml up -d

# 5. Attendre 60 secondes
sleep 60
```

---

## Déploiement avec Ansible

### Structure du Playbook

```
deploy.yml
├── Pre-tasks: Vérifications système
├── Tasks:
│   ├── Installation des prérequis
│   ├── Installation de Docker
│   ├── Installation de Docker Compose
│   ├── Configuration de Docker
│   ├── Clonage des dépôts
│   ├── Configuration de l'application
│   ├── Configuration de la sécurité
│   ├── Build des images
│   ├── Lancement de l'application
│   └── Lancement de la sécurité
└── Post-tasks: Rapport final
```

### Exécution

```bash
# Afficher les tâches qui seront exécutées
sudo ansible-playbook deploy.yml -i inventory.ini --check

# Exécuter avec verbosité
sudo ansible-playbook deploy.yml -i inventory.ini -vvv

# Exécuter une tâche spécifique
sudo ansible-playbook deploy.yml -i inventory.ini --tags "docker"
```

### Variables personnalisables

Éditer `deploy.yml` et modifier les variables:
```yaml
vars:
    app_repo: "https://github.com/ynov-cd/Open-source-M2-cyber-2026"
    app_path: "/opt/secure-app"  # Chemin d'installation
    docker_compose_version: "v2.20.0"
    domain_name: "localhost"
```

---

## Déploiement Manuel

### Étape 1 : Installation de Docker

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker.io docker-compose

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker

# Vérifier
docker --version
docker-compose --version
```

### Étape 2 : Cloner les dépôts

```bash
# Créer le répertoire
mkdir -p /opt/secure-app
cd /opt/secure-app

# Cloner l'application
git clone https://github.com/ynov-cd/Open-source-M2-cyber-2026 app

# Cloner la configuration sécurisée
git clone <votre-repo> config
cp config/* .
```

### Étape 3 : Configuration

```bash
# Créer les répertoires
mkdir -p traefik falco suricata/rules wazuh/rules yara sigma shuffle
mkdir -p database/pgdata

# Permissions
chmod 600 .env
chmod 755 database/pgdata

# Copier les configurations
cp config/falco/* falco/
cp config/suricata/* suricata/
cp config/wazuh/rules/* wazuh/rules/
cp config/yara/* yara/
cp config/sigma/* sigma/
```

### Étape 4 : Build et Lancement

```bash
# Build
docker-compose build --no-cache

# Vérifier la configuration
docker-compose config | head -50

# Lancer
docker-compose up -d

# Attendre
sleep 30

# Vérifier
docker-compose ps
```

### Étape 5 : Stack Sécurité

```bash
# Créer les certificats Wazuh (optionnel)
mkdir -p wazuh/wazuh_indexer_ssl_certs/certs
# Les certificats seront auto-générés

# Lancer la stack
docker-compose -f docker-compose.security.yml up -d

# Attendre
sleep 60

# Vérifier
docker-compose -f docker-compose.security.yml ps
```

---

## Vérification du Déploiement

### Status des Conteneurs

```bash
cd /opt/secure-app

# Application
docker-compose ps
# Devrait afficher: traefik, frontend, backend, db - tous UP

# Sécurité
docker-compose -f docker-compose.security.yml ps
# Devrait afficher: falco, suricata, wazuh, wazuh-indexer, etc - tous UP
```

### Health Checks

```bash
# Vérifier les health checks
docker-compose ps | grep "healthy"

# Voir les logs d'un health check
docker logs backend 2>&1 | grep -i health
```

### Connectivité

```bash
# Test application
curl http://localhost/
# Devrait retourner le HTML du frontend

# Test API
curl http://localhost/api/
# Devrait retourner une réponse JSON

# Test Traefik
curl http://localhost:8080
# Devrait retourner le dashboard

# Test Wazuh
curl -k https://localhost:443 2>/dev/null | head -20
# Devrait retourner la page de login
```

---

## Accès aux Services

### Application

| Service | URL | Accès |
|---------|-----|-------|
| **Frontend** | http://localhost/ | Public |
| **API** | http://localhost/api/ | Public |
| **API Health** | http://localhost:3000/health | Internal |
| **Database** | localhost:5432 | Internal only |

Credentials DB:
- User: `postgres`
- Password: `securepass123`
- Database: `appdb`

### Infrastructure

| Service | URL | Credentials |
|---------|-----|-------------|
| **Traefik Dashboard** | http://localhost:8080 | Aucun |
| **Nginx Config** | See logs | - |

### Security Stack

| Service | URL | Credentials |
|---------|-----|-------------|
| **Wazuh Manager API** | https://localhost:55000 | admin/admin |
| **Wazuh Dashboard** | https://localhost:443 | admin/admin |
| **Wazuh Indexer** | https://localhost:9200 | admin/SecurePassword123! |
| **Shuffle** | http://localhost:3001 | admin/admin |
| **Falco Logs** | /var/log/falco/ | - |
| **Suricata Logs** | /var/log/suricata/ | - |

### Accès via Docker Exec

```bash
# Accéder au backend
docker exec -it backend /bin/sh

# Accéder à la DB
docker exec -it postgres psql -U postgres -d appdb

# Voir les logs Falco
docker exec -it falco tail -f /var/log/falco/alerts.json

# Voir les logs Suricata
docker exec -it suricata tail -f /var/log/suricata/eve.json | jq '.'

# Accéder à Wazuh
docker exec -it wazuh /var/ossec/bin/wazuh-control info
```

---

## Tests de Sécurité

### Test Automatisé

```bash
# Lancer tous les tests
bash test-security.sh

# Tests individuels

# 1. Test exécution shell
docker exec -it backend /bin/sh
# => Falco alerte immédiatement

# 2. Test injection SQL
curl "http://localhost/api/users?id=1' OR '1'='1"
# => Suricata alerte

# 3. Test RCE
curl "http://localhost/api/file?path=/etc/passwd|cat"
# => Suricata + Falco alertent

# 4. Test path traversal
curl "http://localhost/api/file?path=../../etc/passwd"
# => Suricata alerte

# 5. Test XSS
curl "http://localhost/api/comment?text=<script>alert('xss')</script>"
# => Suricata alerte
```

### Vérification des Logs

```bash
# Falco
docker exec falco tail -n 50 /var/log/falco/falco.log

# Suricata - EVE JSON
docker exec suricata tail -n 50 /var/log/suricata/eve.json | jq '.rule'

# Suricata - Fast log
docker exec suricata tail -n 50 /var/log/suricata/fast.log

# Wazuh - Alertes
curl -k -u admin:admin https://localhost:55000/security/users/authenticate 2>/dev/null
```

---

## Troubleshooting

### Conteneurs qui crashent

```bash
# Voir les logs
docker-compose logs -f [service-name]

# Redémarrer un service
docker-compose restart [service-name]

# Redémarrer tous les services
docker-compose down && docker-compose up -d
sleep 30
docker-compose -f docker-compose.security.yml up -d
```

### Erreur : "Cannot connect to Docker daemon"

```bash
# Vérifier si Docker tourne
sudo systemctl status docker

# Démarrer Docker
sudo systemctl start docker
sudo systemctl enable docker

# Ajouter votre utilisateur
sudo usermod -aG docker $USER
```

### Erreur : "No space left on device"

```bash
# Nettoyer les images inutilisées
docker system prune -a

# Nettoyer les volumes
docker volume prune

# Vérifier l'espace
df -h /var/lib/docker
```

### Wazuh ne démarre pas

```bash
# Vérifier les logs
docker-compose -f docker-compose.security.yml logs wazuh

# Régénérer les certificats
docker-compose -f docker-compose.security.yml down
rm -rf wazuh/wazuh_indexer_ssl_certs
docker-compose -f docker-compose.security.yml up -d wazuh-indexer
sleep 60
docker-compose -f docker-compose.security.yml up -d
```

### Pas assez de RAM

```bash
# Réduire les limites dans docker-compose.yml
# Changer:
# limits:
#   memory: 512M
# En:
# limits:
#   memory: 256M

# Réduire les workers Suricata
# Éditer suricata/suricata.yaml:
# threading:
#   set-cpu-affinity: no
#   cpu-affinity:
#     - receive-cpu-set:
#         cpu: [0]
#         threads: 1
```

### Logs manquants

```bash
# Vérifier que les volumes sont créés
docker volume ls | grep secure

# Vérifier les permissions
ls -la /var/log/falco/
ls -la /var/log/suricata/

# Redémarrer pour générer des logs
docker-compose restart backend
```

---

## Commands Utiles

```bash
# Répertoire d'application
cd /opt/secure-app

# Logs temps réel
docker-compose logs -f
docker-compose -f docker-compose.security.yml logs -f falco

# Statut complet
docker-compose ps
docker stats

# Nettoyer
docker-compose down
docker-compose down -v  # Avec volumes

# Rebuild
docker-compose build --no-cache
docker-compose up -d

# Voir la configuration
docker-compose config | less

# Afficher les variables d'environnement
docker-compose exec backend env | sort

# Accéder à un conteneur
docker exec -it [container-name] /bin/sh

# Copier un fichier du conteneur
docker cp [container-name]:/path/to/file ./local-file

# Inspecter un network
docker network inspect secure-deployment_app
```

---

## Support et Documentation

- **README.md** : Vue d'ensemble du projet
- **QUICKSTART.md** : Instructions de démarrage rapide  
- **PROJECT_STRUCTURE.md** : Structure des fichiers
- **EXECUTIVE_SUMMARY.md** : Résumé exécutif
- **.github/workflows/security-pipeline.yml** : CI/CD pipeline

Pour plus d'aide:
- Consulter les logs : `docker-compose logs -f`
- Vérifier les services : `docker ps`
- Lire la documentation officielle des outils
