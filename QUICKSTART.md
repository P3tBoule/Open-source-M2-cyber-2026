# Instruction de Déploiement Rapide

## Option 1: Avec Ansible (Recommandé)

### Prérequis
```bash
sudo apt-get update
sudo apt-get install -y ansible python3-pip
pip3 install ansible
```

### Lancement
```bash
# Clone le dépôt
git clone <URL_DU_REPO> && cd secure-deployment

# Lancer le playbook (demandera le mot de passe sudo)
ansible-playbook -i inventory.ini deploy.yml

# Ou directement:
ansible-playbook deploy.yml
```

### Suivi du déploiement
```bash
# Dans un autre terminal, vérifier les logs
tail -f /opt/secure-app/docker-compose.log
docker-compose -f /opt/secure-app/docker-compose.yml ps
```

**Durée estimée**: 30-40 minutes (dépend de la vitesse d'Internet et de la machine)

---

## Option 2: Script Bash (Alternative)

### Lancement
```bash
# Clone le dépôt
git clone <URL_DU_REPO> && cd secure-deployment

# Rendre le script exécutable
chmod +x deploy.sh

# Lancer le déploiement
sudo ./deploy.sh
```

**Avantage**: Aucune dépendance Ansible requise
**Durée estimée**: 30-40 minutes

---

## Option 3: Déploiement Manuel (Avancé)

```bash
# 1. Installer les prérequis
sudo apt-get update && sudo apt-get install -y docker.io docker-compose git

# 2. Cloner l'application
mkdir -p /opt/secure-app && cd /opt/secure-app
git clone https://github.com/ynov-cd/Open-source-M2-cyber-2026 app

# 3. Copier les fichiers de configuration
cp docker-compose.yml docker-compose.security.yml .env .
cp Dockerfile.* nginx.conf .

# 4. Créer les répertoires
mkdir -p traefik falco/rules suricata/rules wazuh/rules yara sigma shuffle database/pgdata

# 5. Copier les configurations
cp falco/* falco/
cp suricata/* suricata/
# ... etc

# 6. Lancer l'application
docker-compose build
docker-compose up -d

# 7. Attendre 30 secondes, puis la stack sécurité
docker-compose -f docker-compose.security.yml up -d

# 8. Attendre 60 secondes
sleep 60

# 9. Vérifier
docker-compose ps
docker-compose -f docker-compose.security.yml ps
```

---

## Vérification Post-Déploiement

### Application en ligne?
```bash
curl -I http://localhost/
# Doit retourner: HTTP/1.1 200 OK
```

### Services actifs?
```bash
docker-compose ps
docker-compose -f docker-compose.security.yml ps
# Tous les services doivent être "Up"
```

### Logs sains?
```bash
# Backend
docker-compose logs backend | tail -20

# Wazuh
docker-compose -f docker-compose.security.yml logs wazuh | tail -20

# Falco
docker-compose -f docker-compose.security.yml logs falco | tail -20
```

---

## Accès aux Services

### Application
- **Frontend**: http://localhost/
- **Backend API**: http://localhost/api/
- **Database** (interne): postgresql://localhost:5432 (données: app/backend/server.js)

### Monitoring
- **Traefik Dashboard**: http://localhost:8080
- **Wazuh Dashboard**: https://localhost:443
  - Utilisateur: `admin`
  - Mot de passe: `admin`
- **Shuffle SOAR**: http://localhost:3001
- **Wazuh API**: https://localhost:55000

### Logs & Alertes
- **Falco Logs**: `/var/log/falco/falco.log`
- **Suricata Alerts**: `/var/log/suricata/eve.json`
- **Wazuh Alerts**: Wazuh Dashboard ou API

---

## Troubleshooting

### "Impossible de se connecter à Docker"
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### "Port déjà utilisé"
```bash
# Trouver et arrêter les services existants
sudo lsof -i :80
sudo lsof -i :443
sudo lsof -i :5432
```

### "Pas assez de RAM"
```bash
# Réduire les ressources dans docker-compose.yml
# Réduire les workers dans suricata/suricata.yaml
```

### "Certificats Wazuh manquants"
```bash
cd /opt/secure-app
./generate-certs.sh
docker-compose -f docker-compose.security.yml restart wazuh
```

---

## Commandes Utiles

```bash
# Aller au répertoire d'application
cd /opt/secure-app

# Voir les conteneurs en temps réel
watch docker-compose ps

# Voir tous les logs
docker-compose logs -f

# Redémarrer l'application complète
docker-compose restart

# Arrêter tout (sans supprimer les données)
docker-compose down

# Arrêter tout et supprimer les données
docker-compose down -v

# Voir les stats (CPU, RAM, réseau)
docker stats

# Inspecter un conteneur
docker inspect backend

# Accéder au shell d'un conteneur
docker exec -it backend /bin/sh
docker exec -it postgres psql -U postgres -d appdb

# Voir les networks
docker network ls
docker network inspect secure-deployment_app
```

---

## Points Clés de Sécurité

1. **Utilisateurs non-root** ✅
   - Tous les conteneurs exécutés avec un utilisateur dédié
   - UID < 1000 pour l'isolation

2. **Read-only filesystems** ✅
   - Racine en lecture seule où possible
   - Tmpfs pour les fichiers temporaires

3. **Limitations de ressources** ✅
   - CPU et RAM limités par conteneur
   - Évite les attaques DoS

4. **Monitoring continu** ✅
   - Falco: comportement processus
   - Suricata: trafic réseau
   - Wazuh: agrégation logs

5. **Isolation réseau** ✅
   - 3 réseaux Docker séparés
   - Database privée (pas d'accès externe)

---

## Support & Documentation

- [README.md](./README.md) - Documentation complète
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Falco Documentation](https://falco.org/docs/)
- [Suricata Documentation](https://suricata.io/documentation/)

---

**Dernière mise à jour**: 2026-04-23
**Version**: 1.0.0
