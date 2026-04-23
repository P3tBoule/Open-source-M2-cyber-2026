# Fichier de Structure du Projet

Ce document décrit l'organisation et le contenu du projet de sécurisation d'application 3-tiers.

## 📁 Architecture des Fichiers

```
secure-deployment/
├── 📘 Documentation
│   ├── README.md                      # Documentation complète du projet
│   ├── QUICKSTART.md                  # Guide de démarrage rapide
│   └── PROJECT_STRUCTURE.md           # Ce fichier
│
├── 🐳 Conteneurisation & Orchestration
│   ├── Dockerfile.backend             # Dockerfile sécurisé Node.js backend
│   ├── Dockerfile.frontend            # Dockerfile sécurisé Nginx frontend
│   ├── docker-compose.yml             # Orchestration application (3 conteneurs)
│   ├── docker-compose.security.yml    # Orchestration stack sécurité (7 conteneurs)
│   ├── nginx.conf                     # Configuration Nginx sécurisée
│   └── .env                           # Variables d'environnement
│
├── 🔐 Sécurité & Monitoring
│   ├── falco/
│   │   ├── falco.yaml                 # Configuration Falco
│   │   └── falco-rules.yaml           # Règles personnalisées Falco
│   ├── suricata/
│   │   ├── suricata.yaml              # Configuration Suricata IDS
│   │   ├── rules/
│   │   │   └── custom-rules.rules     # Règles détection Suricata
│   │   └── custom-rules.rules         # Copie pour backward compat
│   ├── wazuh/
│   │   └── rules/
│   │       └── custom_rules.xml       # Règles Wazuh SIEM
│   ├── yara/
│   │   └── nodejs_malware.yar         # Règles YARA pour malware Node.js
│   └── sigma/
│       └── detection_rules.yaml       # Règles Sigma (format standard)
│
├── 🚀 Automation & Déploiement
│   ├── deploy.yml                     # Playbook Ansible (complet)
│   ├── deploy.sh                      # Script bash déploiement (alternative)
│   ├── inventory.ini                  # Inventaire Ansible
│   ├── ansible.cfg                    # Configuration Ansible
│   ├── generate-certs.sh              # Script génération certificats Wazuh
│   └── transpile-sigma.sh             # Script transpilation Sigma
│
├── 🧪 Tests
│   └── test-security.sh               # Script de tests de détection
│
├── 🔄 CI/CD
│   └── .github/workflows/
│       └── security-pipeline.yml      # GitHub Actions workflow
│
├── 📝 Configuration
│   └── .gitignore                     # Fichiers à ignorer git
│
└── 📦 Application
    └── app/                           # Clonée par deploy.yml/deploy.sh
        ├── backend/                   # API Node.js
        ├── frontend/                  # Interface Nginx
        ├── database/                  # Scripts PostgreSQL
        └── compose.yml                # Original (non utilisé)
```

## 📊 Conteneurs Déployés

### Application Stack (docker-compose.yml)

| Conteneur | Image | Port | Rôle |
|-----------|-------|------|------|
| **traefik** | traefik:v3.0-alpine | 80, 8080 | Reverse proxy |
| **backend** | node:22-alpine | 3000 | API Node.js |
| **frontend** | nginx:alpine | 80 | Interface web |
| **db** | postgres:16-alpine | 5432 | Base de données |

### Security Stack (docker-compose.security.yml)

| Conteneur | Image | Port | Rôle |
|-----------|-------|------|------|
| **falco** | falcosecurity/falco:latest | - | Monitoring runtime |
| **suricata** | jasonish/suricata:latest | - | IDS réseau |
| **wazuh** | wazuh/wazuh:latest | 55000 | Manager SIEM |
| **wazuh-indexer** | wazuh/wazuh-indexer:latest | 9200 | Indexer (OpenSearch) |
| **wazuh-dashboard** | wazuh/wazuh-dashboard:latest | 443 | Dashboard |
| **shuffle-backend** | frikky/shuffle:latest | 5001 | SOAR backend |
| **shuffle-frontend** | frikky/shuffle-frontend:latest | 3001 | SOAR interface |

(+ dépendances: elasticsearch, redis, rabbitmq)

## 🔧 Processus de Déploiement

### 1️⃣ Phase de Préparation
- Installation Docker & Docker Compose
- Installation des prérequis système
- Clonage du dépôt application

### 2️⃣ Phase de Configuration
- Copie des Dockerfiles
- Création des répertoires de config
- Copie des fichiers de configuration

### 3️⃣ Phase de Build
- Build des images Docker
- Création des réseaux
- Validation de la configuration

### 4️⃣ Phase de Lancement
- Démarrage des conteneurs application
- Démarrage de la stack sécurité
- Vérification de la santé

### 5️⃣ Phase de Validation
- Healthchecks
- Vérification de connectivité
- Tests de sécurité (optionnel)

## 🛡️ Mesures de Sécurité Implémentées

### Au niveau Docker
- ✅ Utilisateurs non-root (UID > 1000)
- ✅ Read-only root filesystem
- ✅ Limitation des capacités (CAP_DROP ALL)
- ✅ Limitation des ressources CPU/RAM
- ✅ Healthchecks configurés
- ✅ Multi-stage builds
- ✅ Images minimales (Alpine)

### Au niveau Réseau
- ✅ Traefik reverse proxy
- ✅ Réseaux Docker séparés (app, traefik, security)
- ✅ Database privée (pas d'exposition)
- ✅ Headers de sécurité HTTP (CSP, X-Frame-Options, etc.)

### Au niveau Monitoring
- ✅ Falco: Détection comportement runtime
- ✅ Suricata: Analyse trafic réseau
- ✅ Wazuh: Agrégation & corrélation logs
- ✅ Shuffle: Automatisation des réponses

### Au niveau CI/CD
- ✅ GitHub Actions workflow
- ✅ Scan vulnérabilités (npm audit)
- ✅ SBOM generation (Trivy)
- ✅ Licence checking
- ✅ IaC scanning

## 📈 Règles de Détection

### Falco (Runtime)
| Règle | Sévérité | Détection |
|-------|----------|-----------|
| Shell execution | CRITICAL | /bin/bash, /bin/sh dans backend |
| Sensitive file access | HIGH | /etc/passwd, /etc/shadow, /root/.ssh |
| /tmp execution | HIGH | Processus lancé depuis /tmp |
| Package installation | HIGH | apt, npm, pip, apk |

### Suricata (Réseau)
| Catégorie | Règles | Patterns |
|-----------|--------|----------|
| SQL Injection | 3 | UNION SELECT, Boolean blind |
| RCE | 3 | ;, \|, &, $(...), \`\` |
| Path Traversal | 4 | ../, %2e%2e, double traversal |
| XSS | 2 | <script>, onerror, javascript: |
| General | 5 | Anomalies, DoS, etc. |

### Wazuh (SIEM)
| Règle | Level | Trigger |
|-------|-------|---------|
| Shell execution (Falco) | 12 | Falco alert |
| SQL Injection (Suricata) | 12 | Suricata alert |
| RCE Attempt | 13 | Suricata alert |
| Multiple attacks | 13 | Corrélation 3 alertes |
| Backend compromise | 14 | Multiple Falco alerts |

### YARA
| Règle | Détection |
|-------|-----------|
| Obfuscation | eval(), Buffer.from(), String.fromCharCode |
| Backdoor | net.createServer(), child_process.spawn() |
| C2 | http.request(), fetch(), webhooks |
| Mining | Patterns crypto + worker |

### Sigma
| Règle | SIEM Target |
|-------|------------|
| Shell detection | Wazuh, Elastic, Splunk |
| Sensitive access | Wazuh, ArcSight |
| Tmp execution | Tous |
| Attack patterns | Corrélation multi-sources |

## 🚀 Commandes Clés

### Déploiement
```bash
# Avec Ansible
ansible-playbook deploy.yml

# Avec script bash
sudo ./deploy.sh

# Manuel
cd /opt/secure-app
docker-compose build && docker-compose up -d
docker-compose -f docker-compose.security.yml up -d
```

### Monitoring
```bash
# Logs en temps réel
docker-compose logs -f
docker-compose -f docker-compose.security.yml logs -f falco

# Alertes
docker exec suricata tail -f /var/log/suricata/eve.json | jq '.'
docker exec wazuh tail -f /var/log/wazuh/alerts.json | jq '.'

# Statut
docker-compose ps
docker stats
```

### Tests
```bash
# Tests de sécurité
./test-security.sh

# Scan manuel d'image
trivy image backend:latest
trivy config docker-compose.yml

# Vérification des règles
docker exec suricata suricatasc -c 'ruleset-show'
docker exec falco suricata -T -c /etc/suricata/suricata.yaml
```

## 📚 Documentation Externe

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Falco Rules Documentation](https://falco.org/docs/rules/)
- [Suricata IDS](https://suricata.io/documentation/)
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## 🔄 Workflow GitHub Actions

Le fichier `.github/workflows/security-pipeline.yml` exécute:

1. **Scan dépendances** - npm audit
2. **SBOM generation** - Trivy + CycloneDX
3. **Licence check** - Détection copyleft
4. **IaC scan** - Dockerfiles et compose.yml
5. **Image build** - Construction et scan

## 📋 Checklist de Validation

- [ ] Ansible/Python3 installé
- [ ] Application accessible sur http://localhost/
- [ ] Traefik Dashboard actif (http://localhost:8080)
- [ ] Wazuh Dashboard accessible (https://localhost:443)
- [ ] Falco logs générés
- [ ] Suricata eve.json popuplé
- [ ] Tests de sécurité passant
- [ ] Aucun conteneur en erreur
- [ ] RAM utilisée < 50GB
- [ ] Tous les certificats présents

## 🔐 Points de Vigilance

⚠️ **Production**: 
- Utiliser des secrets management (Vault, K8s Secrets)
- Activer HTTPS avec certificats valides
- Configurer une authentification Wazuh robuste
- Mettre en place une sauvegarde des données
- Monitorer les ressources système

⚠️ **Sécurité**:
- Ne jamais commiter .env en production
- Changer les mots de passe par défaut
- Mettre à jour régulièrement les images Docker
- Monitorer les CVE dans les dépendances

## 📞 Support & Ressources

Consultez `README.md` pour:
- Détails complets de chaque composant
- Troubleshooting avancé
- Exemples de curl pour les tests
- Explications détaillées des règles

---

**Date**: 2026-04-23
**Version**: 1.0.0
**Auteur**: Security Team - Ynov Cyber 2026
