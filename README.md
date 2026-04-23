# Sécurisation Globale d'une Application 3-Tiers

## 📋 Vue d'ensemble

Ce projet met en place une infrastructure sécurisée complète autour d'une application Node.js 3-tiers basée sur le MVP du dépôt [Open-source-M2-cyber-2026](https://github.com/ynov-cd/Open-source-M2-cyber-2026).

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Stack                         │
├─────────────────────────────────────────────────────────────┤
│  Frontend (Nginx)  →  Traefik (Reverse Proxy)  →  Backend    │
│                                                   (Node.js)   │
│                          ↓                                     │
│                    PostgreSQL Database                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Security Stack                             │
├─────────────────────────────────────────────────────────────┤
│  ├─ Falco (Runtime Monitoring)                              │
│  ├─ Suricata (Network IDS)                                  │
│  ├─ Wazuh (SIEM)                                            │
│  ├─ Shuffle (SOAR)                                          │
│  ├─ YARA Rules                                              │
│  └─ Sigma Rules                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Objectifs Réalisés

### 1. ✅ Sécurisation du Cycle de Vie
- **GitHub Actions Workflow** automatisé à chaque push
- Scan des vulnérabilités applicatives avec npm audit
- Génération et analyse SBOM avec Trivy (format CycloneDX)
- Vérification des licences (détection des licences copyleft)
- Analyse Infrastructure as Code (Trivy pour Dockerfiles et compose.yml)

### 2. ✅ Conteneurisation Sécurisée
- **Dockerfiles Multi-stage** respectant les bonnes pratiques
- Utilisateurs non-root dans tous les conteneurs
- Read-only root filesystems où applicable
- Capability dropping (CAP_DROP ALL)
- Health checks configurés
- Limitation des ressources CPU/Memory

### 3. ✅ Reverse Proxy & Orchestration
- **Traefik** comme reverse proxy sécurisé
- Routage intelligent du trafic
- Headers de sécurité HTTP
- Configuration Nginx optimisée avec CSP

### 4. ✅ Automation Déploiement
- **Playbook Ansible** complet pour l'orchestration
- Installation automatique de Docker/Docker Compose
- Configuration système sécurisée
- Déploiement complètement automatisé

### 5. ✅ Stack de Sécurité Intégrée

#### Falco (Runtime Security)
- Détection des exécutions de shell dans les conteneurs
- Surveillance des accès aux fichiers sensibles
- Détection des exécutions depuis /tmp
- Alerte sur les installations de paquets

#### Suricata (Network IDS)
- Détection d'injections SQL
- Détection de Remote Code Execution (RCE)
- Détection de traversée de répertoire (..)
- Détection de tentatives XSS

#### Wazuh (SIEM)
- Agrégation des logs de tous les outils
- Corrélation des événements
- Alertes multi-étages
- Dashboard centralisé

#### Shuffle (SOAR)
- Workflow d'automatisation des incidents
- Intégration webhooks Wazuh
- Actions de réponse automatiques

#### YARA Rules
- Détection de scripts Node.js malveillants
- Identification de payloads obfuscés
- Détection de patterns de backdoor

#### Sigma Rules
- Détection coordonnée par le SIEM
- Corrélation d'alertes Falco/Suricata
- Patterns d'attaque multi-étapes

## 🚀 Déploiement Rapide

### Prérequis

- Linux (Ubuntu 20.04+, Debian 11+)
- Au minimum 16GB de RAM (le stack de sécurité est gourmand)
- 50GB d'espace disque libre
- Accès sudo/root

### Installation & Lancement

```bash
# 1. Cloner le dépôt
git clone <votre-repo> secure-deployment
cd secure-deployment

# 2. Vérifier les prérequis
python3 -m pip install ansible

# 3. Lancer le playbook Ansible (vous serez invité à entrer votre mot de passe)
ansible-playbook deploy.yml

# 4. Attendre la fin du déploiement (30-40 minutes selon la machine)
```

### Vérification du Déploiement

```bash
# Accéder au répertoire d'application
cd /opt/secure-app

# Vérifier le statut des conteneurs
docker-compose ps
docker-compose -f docker-compose.security.yml ps

# Voir les logs en temps réel
docker-compose logs -f
docker-compose -f docker-compose.security.yml logs -f falco

# Accéder aux services
# Application: http://localhost/
# Traefik: http://localhost:8080
# Wazuh: https://localhost:443 (admin/admin)
# Shuffle: http://localhost:3001
```

## 📊 Architecture Détaillée

### Application Stack

#### Frontend
- **Image**: Nginx Alpine
- **Port**: 80 (via Traefik)
- **Sécurité**: 
  - Utilisateur non-root (www-data)
  - Read-only filesystem
  - Headers de sécurité (CSP, X-Frame-Options, etc.)
  - Gzip compression

#### Backend
- **Image**: Node.js 22 Alpine (Multi-stage)
- **Port**: 3000 (interne, 80 via Traefik)
- **Sécurité**:
  - Utilisateur non-root (nodejs)
  - Deps minimales uniquement
  - Healthcheck intégré
  - Limité à 1 CPU / 512MB RAM

#### Database
- **Image**: PostgreSQL 16 Alpine
- **Port**: 5432 (interne seulement)
- **Sécurité**:
  - Read-only root filesystem
  - Tmpfs pour /tmp et /var/run
  - Limité à 1 CPU / 512MB RAM
  - Healthcheck

#### Traefik
- **Port**: 80 (HTTP)
- **Dashboard**: 8080
- **Sécurité**:
  - Reverse proxy sécurisé
  - Routage dynamique
  - API protégée

### Security Stack (Séparé)

#### Falco
- **Analyse**: Comportement runtime des conteneurs
- **Règles**: 5+ règles de sécurité personnalisées
- **Logs**: JSON avec contexte complet

#### Suricata
- **Analyse**: Trafic réseau
- **Règles**: 20+ règles de détection d'attaques
- **Logs**: EVE JSON + alertes structurées

#### Wazuh
- **Indexer**: OpenSearch (Elasticsearch fork)
- **Manager**: Agrégation et corrélation
- **Dashboard**: Interface web sécurisée
- **Règles**: 100+ règles incluant les custom rules

#### Shuffle
- **Workflows**: Basés sur les webhooks Wazuh
- **Actions**: Email, tickets, etc.
- **Intégration**: API extensible

## 🔒 Détails de Sécurité

### GitHub Actions Workflow

Le workflow s'exécute à chaque push et comprend:

```yaml
Jobs:
1. Scan des vulnérabilités (npm audit)
2. Génération SBOM (Trivy + CycloneDX)
3. Vérification des licences
4. Analyse IaC (Dockerfiles + compose.yml)
5. Build et scan des images Docker
```

#### Exécution manuelle:

```bash
# Afficher les résultats
cd app
git log --oneline | head -5
```

### Regles de Détection

#### Falco - Exécution de Shell

```yaml
Rule: Shell executed in Backend container
- Monitore: bash, sh, zsh, ksh, csh
- Container: backend seulement
- Sévérité: CRITICAL
- Alerte: Au premier déclenchement
```

Test:
```bash
docker exec -it backend /bin/sh
# => Alerte Falco immédiate
# => Enregistrée dans /var/log/falco/
```

#### Suricata - Injection SQL

```yaml
Rules:
1. SQL Injection Basic (UNION, SELECT, etc.)
2. SQL Injection Boolean-blind
3. Détection basée sur pcre

Alerte: Any injection attempt
```

Test:
```bash
curl "http://localhost/api/search?q=' OR '1'='1"
# => Alerte Suricata dans eve.json
```

#### Suricata - Remote Code Execution

```yaml
Rules:
1. OS Command Injection (;|&)
2. Command substitution ($(...) ou backticks)
3. Pipe + redirection

Alerte: Any pattern detected
```

Test:
```bash
curl "http://localhost/api/upload?file=test;cat /etc/passwd"
# => Alerte Suricata immédiate
```

#### Suricata - Path Traversal

```yaml
Rules:
1. Unix style: ../
2. Encoded: %2e%2e%2f
3. Windows style: ..\

Alerte: Any traversal attempt
```

Test:
```bash
curl "http://localhost/api/files?path=../../etc/passwd"
# => Alerte Suricata immédiate
```

## 📈 Commandes de Monitoring

### Consulter les Logs Falco

```bash
# Logs en temps réel
docker-compose -f docker-compose.security.yml logs -f falco

# Tous les fichiers de logs
docker exec falco tail -f /var/log/falco/falco.log

# Alertes JSON
docker exec falco tail -f /var/log/falco/alerts.json
```

### Consulter les Logs Suricata

```bash
# Logs EVE JSON (formaté)
docker exec suricata tail -f /var/log/suricata/eve.json | jq '.'

# Alerts rapides
docker exec suricata tail -f /var/log/suricata/fast.log

# HTTP logs
docker exec suricata tail -f /var/log/suricata/http.log
```

### Consulter Wazuh

#### Via l'API

```bash
# Lister les alertes (remplacer les credentials)
curl -k -u admin:admin https://localhost:55000/security/users/authenticate

# Récupérer les alertes des 24 dernières heures
curl -k -u admin:admin \
  'https://localhost:55000/events?query=alert.rule.level>=10&sort=-timestamp&limit=100'
```

#### Via le Dashboard

```
Accès: https://localhost:443
Utilisateur: admin
Mot de passe: admin

Navigation:
- Security Events -> Wazuh Alerts
- Integrity Monitoring -> Files
- Log Analysis -> Logs
```

### Commandes utiles

```bash
# Afficher la composition des services
cd /opt/secure-app
docker-compose config

# Vérifier les ressources utilisées
docker stats

# Voir les networks
docker network ls
docker network inspect secure-deployment_app
docker network inspect secure-deployment_traefik
docker network inspect secure-deployment_security

# Accéder à un conteneur
docker exec -it backend /bin/sh
docker exec -it postgres psql -U postgres -d appdb

# Voir les volumes
docker volume ls
docker volume inspect secure-deployment_wazuh_etc_uid

# Logs détaillés
docker compose logs backend --follow --tail 50
docker compose logs -f traefik | grep -i error
```

## 🧪 Tests de Sécurité

### Test 1: Exécution de Shell dans Backend

```bash
# Tentative 1 - Via docker exec
docker exec -it backend /bin/sh

# Tentative 2 - Via injection dans l'app
curl "http://localhost/api/execute?cmd=sh"

# ✅ Falco alerte
# ✅ Wazuh log l'alerte
# ✅ Shuffle peut envoyer notification
```

### Test 2: Injection SQL

```bash
# Tentative classique
curl "http://localhost/api/users?id=1' OR '1'='1"

# Tentative avancée
curl "http://localhost/api/search?q='; DROP TABLE users; --"

# ✅ Suricata alerte
# ✅ Wazuh corrèle les événements
```

### Test 3: Remote Code Execution

```bash
# Injection de commande basique
curl "http://localhost/api/file?path=/etc/passwd|cat"

# Injection avec backticks
curl "http://localhost/api/exec?cmd=\`whoami\`"

# Injection avec $()
curl "http://localhost/api/run?cmd=\$(id)"

# ✅ Suricata détecte
# ✅ Falco alerte si exécution réelle
# ✅ Wazuh agrège tout
```

### Test 4: Path Traversal

```bash
# Tentative simple
curl "http://localhost/api/file?path=../../etc/passwd"

# Tentative encodée
curl "http://localhost/api/file?path=%2e%2e%2fetc%2fpasswd"

# Tentative multiple
curl "http://localhost/api/file?path=../../../../../../../etc/passwd"

# ✅ Suricata détecte tous les patterns
```

### Test 5: Cross-Site Scripting

```bash
# XSS simple
curl "http://localhost/api/comment?text=<script>alert('xss')</script>"

# XSS avec événement
curl "http://localhost/api/profile?name=<img src=x onerror=alert('xss')>"

# ✅ Suricata alerte
```

## 📝 Choix de Sécurité Justifiés

### 1. Multi-stage builds Docker

**Raison**: Réduire la surface d'attaque en excluant les dépendances de build

```dockerfile
FROM node:22-alpine AS dependencies
# Installe les deps
FROM node:22-alpine
# Copie uniquement les modules produits
```

### 2. Utilisateurs non-root

**Raison**: Limiter les dégâts en cas de compromise du processus

```
USER nodejs (UID 1001)
USER www-data (UID 101)
```

### 3. Read-only filesystem

**Raison**: Empêcher la modification de fichiers critiques

```yaml
read_only_root_filesystem: true
tmpfs:
  - /var/run
  - /var/cache/nginx
  - /var/log/nginx
```

### 4. Capability dropping

**Raison**: Supprimer les capacités système inutiles

```yaml
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE  # Nécessaire pour écouter sur le port)
```

### 5. Falco + Suricata + Wazuh

**Raison**: Défense en profondeur (3 couches):
- **Falco**: Comportement du processus
- **Suricata**: Trafic réseau
- **Wazuh**: Agrégation et corrélation

### 6. Séparation des réseaux Docker

**Raison**: Isolation du trafic de sécurité du trafic applicatif

```
- br_app (Frontend ↔ Backend ↔ DB)
- br_traefik (Traefik ↔ Frontend/Backend)
- br_security (Falco ↔ Suricata ↔ Wazuh)
```

### 7. Ressources limitées

**Raison**: Stack de sécurité gourmande en RAM

```yaml
limits:
  cpus: '1'
  memory: 512M
reservations:
  cpus: '0.5'
  memory: 256M
```

## 🐛 Failles Potentielles & Mitigations

### Faille 1: Fuite de credentials dans .env

**Découverte**: Les variables de base de données sont en clair

```env
DB_PASSWORD=securepass123  # ❌ Visible en clair
```

**Mitigation Implémentée**:
- Fichier `.env` en mode 0600 (readable owner only)
- Utilisation de secrets Docker en production recommandée
- Variables sensibles ne devraient jamais être en clair

```bash
chmod 600 .env
```

### Faille 2: TRAEFIK_INSECURE=true

**Découverte**: Dashboard Traefik accessible sans authentification

**Mitigation Implémentée**:
- Dashboard limité à localhost seulement
- En production, ajouter une authentification Basic

```yaml
# À ajouter en production:
labels:
  - "traefik.http.middlewares.auth.basicauth.users=admin:$$2y$$05$$..."
```

### Faille 3: Application vulnérable (non-modifiable)

**Découverte**: L'application elle-même peut avoir des vulnérabilités

**Mitigation Implémentée**:
- Isolation par conteneur
- Subnet privé pour la base de données
- Limitations de ressources
- Monitoring en temps réel

### Faille 4: Wazuh sans HTTPS en interne

**Découverte**: Communications non chiffrées entre composants

**Mitigation Implémentée**:
- Wazuh sur réseau privé Docker seulement
- Dashboard en HTTPS (self-signed)
- En production: Certificats valides recommandés

### Faille 5: Logs non persistants

**Découverte**: Les logs Falco/Suricata sont perdus au redémarrage

**Mitigation Recommandée**:
```bash
# Ajouter la persistence:
volumes:
  - /var/log/falco:/var/log/falco
  - /var/log/suricata:/var/log/suricata
```

## 🔧 Troubleshooting

### Conteneurs qui crashent au démarrage

```bash
# Vérifier les logs
docker-compose logs -f [service]

# Redémarrer proprement
docker-compose down -v
docker-compose up -d

# Attendre que les health checks passent
watch docker-compose ps
```

### Wazuh qui ne démarre pas

```bash
# Les certificats peuvent être manquants
# Régénérer les certificats
docker-compose -f docker-compose.security.yml down
rm -rf wazuh/wazuh_indexer_ssl_certs
docker-compose -f docker-compose.security.yml up -d

# Attendre 2-3 minutes
```

### RAM insuffisante

```bash
# Réduire les ressources
# Éditer docker-compose.yml et docker-compose.security.yml
# Réduire les limits et reservations
# Réduire les workers Suricata dans suricata.yaml
```

### Pas d'alertes Suricata

```bash
# Vérifier que les règles sont chargées
docker exec suricata suricata -T -c /etc/suricata/suricata.yaml

# Vérifier la syntaxe des règles
docker exec suricata suricatasc -c "ruleset-show"

# Voir les logs Suricata
docker-compose -f docker-compose.security.yml logs suricata
```

## 📚 Documentation de Référence

### Outils Utilisés

- [Docker Documentation](https://docs.docker.com/)
- [Traefik Proxy](https://doc.traefik.io/)
- [Falco Rules](https://falco.org/docs/)
- [Suricata](https://suricata.io/documentation/)
- [Wazuh](https://documentation.wazuh.com/)
- [Shuffle](https://shuffler.io/)
- [YARA Rules](https://yara.readthedocs.io/)
- [Sigma Rules](https://sigmahq.io/)

### Ressources Supplémentaires

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

## 📄 Licence

MIT License - Voir LICENSE file

## 👥 Auteur

Créé dans le cadre du module de sécurité - Ynov Cyber 2026
