# Checklist de Déploiement

## ✅ Avant le Déploiement

- [ ] Machine Linux préparée (Ubuntu 20.04+ ou Debian 11+)
- [ ] Minimum 16GB de RAM disponible
- [ ] 50GB d'espace disque libre
- [ ] Accès sudo/root disponible
- [ ] Connexion Internet stable
- [ ] Git installé
- [ ] Ansible installé (optionnel mais recommandé)

## ✅ Préparation du Dépôt

- [ ] Cloner le dépôt de sécurisation
  ```bash
  git clone <votre-repo> secure-deployment
  cd secure-deployment
  ```

- [ ] Vérifier la structure des fichiers
  ```bash
  ls -la
  # Devrait afficher: Dockerfile.*, docker-compose*.yml, deploy.yml, etc.
  ```

- [ ] Vérifier les permissions des scripts
  ```bash
  chmod +x deploy.sh transpile-sigma.sh test-security.sh
  ```

## ✅ Déploiement (Choix une option)

### Option A : Ansible (Recommandé)

- [ ] Installer Ansible
  ```bash
  sudo apt-get install -y ansible
  ```

- [ ] Lancer le playbook
  ```bash
  sudo ansible-playbook deploy.yml -i inventory.ini
  ```

- [ ] Attendre 30-40 minutes
- [ ] Vérifier le statut final
  ```bash
  cd /opt/secure-app
  docker-compose ps
  docker-compose -f docker-compose.security.yml ps
  ```

### Option B : Script Bash

- [ ] Lancer le script
  ```bash
  sudo bash deploy.sh
  ```

- [ ] Attendre la fin
- [ ] Vérifier à la fin du script

### Option C : Manuel

- [ ] Installer Docker
  ```bash
  sudo apt-get install -y docker.io docker-compose
  ```

- [ ] Cloner l'application
  ```bash
  cd /opt/secure-app
  git clone https://github.com/ynov-cd/Open-source-M2-cyber-2026 app
  cp -r * /opt/secure-app/  # Copier les configs
  ```

- [ ] Créer les répertoires
  ```bash
  mkdir -p traefik falco suricata/rules wazuh/rules yara sigma shuffle database/pgdata
  ```

- [ ] Build et lancer
  ```bash
  docker-compose build
  docker-compose up -d
  sleep 30
  docker-compose -f docker-compose.security.yml up -d
  ```

## ✅ Vérification Post-Déploiement

### Services Application

- [ ] Frontend accessible
  ```bash
  curl http://localhost/
  ```

- [ ] API accessible
  ```bash
  curl http://localhost/api/
  ```

- [ ] Traefik Dashboard
  ```bash
  curl http://localhost:8080
  ```

- [ ] Base de données
  ```bash
  docker exec -it postgres pg_isready -U postgres
  ```

### Services Sécurité

- [ ] Falco en exécution
  ```bash
  docker-compose -f docker-compose.security.yml ps | grep falco
  ```

- [ ] Suricata en exécution
  ```bash
  docker-compose -f docker-compose.security.yml ps | grep suricata
  ```

- [ ] Wazuh en exécution
  ```bash
  docker-compose -f docker-compose.security.yml ps | grep wazuh
  ```

- [ ] Shuffle en exécution
  ```bash
  docker-compose -f docker-compose.security.yml ps | grep shuffle
  ```

### Health Checks

- [ ] Tous les conteneurs "healthy"
  ```bash
  docker-compose ps | grep -E "(healthy|Up \([0-9]+\))"
  ```

- [ ] Aucun conteneur en restart
  ```bash
  docker-compose ps | grep "Restarting\|Exited"
  # Devrait être vide
  ```

## ✅ Tests de Sécurité

### Test 1 : Exécution de Shell

- [ ] Exécuter le test
  ```bash
  docker exec -it backend /bin/sh
  # Devrait être rejeté ou alerté
  ```

- [ ] Vérifier l'alerte Falco
  ```bash
  docker exec falco tail -f /var/log/falco/alerts.json | grep -i "shell"
  ```

### Test 2 : Injection SQL

- [ ] Exécuter le test
  ```bash
  curl "http://localhost/api/users?id=1' OR '1'='1"
  ```

- [ ] Vérifier l'alerte Suricata
  ```bash
  docker exec suricata tail -f /var/log/suricata/eve.json | jq '.rule'
  ```

### Test 3 : Path Traversal

- [ ] Exécuter le test
  ```bash
  curl "http://localhost/api/file?path=../../etc/passwd"
  ```

- [ ] Vérifier l'alerte Suricata
  ```bash
  docker exec suricata tail -f /var/log/suricata/eve.json | grep -i "path"
  ```

### Test 4 : RCE

- [ ] Exécuter le test
  ```bash
  curl "http://localhost/api/cmd?cmd=id"
  ```

- [ ] Vérifier l'alerte
  ```bash
  docker logs wazuh | grep -i "injection"
  ```

## ✅ Configuration Initiale

### Wazuh Dashboard

- [ ] Accéder au dashboard
  ```bash
  # https://localhost:443
  # Utilisateur: admin
  # Mot de passe: admin
  ```

- [ ] Accepter le certificat auto-signé
- [ ] Se connecter
- [ ] Voir le dashboard principal

### Shuffle SOAR

- [ ] Accéder à Shuffle
  ```bash
  # http://localhost:3001
  # Utilisateur: admin
  # Mot de passe: admin
  ```

- [ ] Importer le workflow Wazuh
  ```bash
  # Importer: shuffle/wazuh-alert-workflow.json
  ```

- [ ] Configurer les webhooks
  ```bash
  # Dans Wazuh Settings > Integrations > Shuffle
  ```

## ✅ Documentation

- [ ] Lire le README.md
- [ ] Consulter DEPLOYMENT_GUIDE.md
- [ ] Consulter PROJECT_STRUCTURE.md
- [ ] Consulter QUICKSTART.md
- [ ] Consulter EXECUTIVE_SUMMARY.md

## ✅ Sauvegardes

- [ ] Sauvegarder la configuration
  ```bash
  tar -czf secure-app-backup.tar.gz /opt/secure-app/
  ```

- [ ] Documenter les modifications personnalisées
- [ ] Sauvegarder les certificats Wazuh
  ```bash
  tar -czf wazuh-certs-backup.tar.gz /opt/secure-app/wazuh/
  ```

## ✅ Production (Le Cas Échéant)

- [ ] Modifier les mots de passe par défaut
  ```
  - Wazuh: admin/admin
  - Shuffle: admin/admin
  - PostgreSQL: postgres/securepass123
  ```

- [ ] Générer des certificats valides (non auto-signés)
- [ ] Configurer un reverse proxy HTTPS
- [ ] Ajouter une authentification au Traefik dashboard
- [ ] Configurer les logs persistants
- [ ] Mettre en place une stratégie de backup
- [ ] Configurer la réplication de base de données
- [ ] Mettre en place un monitoring

## ✅ Dépannage

Si des problèmes surviennent:

- [ ] Consulter les logs
  ```bash
  docker-compose logs -f [service]
  docker-compose -f docker-compose.security.yml logs -f [service]
  ```

- [ ] Vérifier l'espace disque
  ```bash
  df -h
  du -sh /var/lib/docker/
  ```

- [ ] Vérifier la RAM
  ```bash
  free -h
  docker stats
  ```

- [ ] Consulter DEPLOYMENT_GUIDE.md troubleshooting section

## ✅ Maintenance Continue

- [ ] Mettre à jour les images Docker régulièrement
  ```bash
  docker-compose pull
  docker-compose up -d
  ```

- [ ] Monitorer les logs Wazuh quotidiennement
- [ ] Examiner les alertes Falco/Suricata
- [ ] Faire des sauvegardes régulières
- [ ] Tester les processus de récupération
- [ ] Mettre à jour les règles de détection

---

**Date de déploiement**: _______________  
**Déployé par**: _______________  
**Environnement**: [ ] Test [ ] Production  
**Notes**: ___________________________________________________

