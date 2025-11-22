#!/bin/bash

cd "$(dirname "$0")"

### --------------------------
### Création et lancement du serveur DNS
### --------------------------

# Build de l'image Docker DNS
docker build -t dns_debian ./images/dns

# Création du conteneur DNS
docker create -it \
    --name entreprise_dns \
    --hostname entreprise_dns \
    --network none \
    --privileged \
    dns_debian

# Démarrage du conteneur DNS
docker start entreprise_dns

# Fonction pour ajouter le namespace Docker
addNetnsList() {
    pid=$(docker inspect -f '{{.State.Pid}}' $1)
    sudo mkdir -p /var/run/netns/
    sudo ln -sf /proc/$pid/ns/net /var/run/netns/$1
}

addNetnsList entreprise_dns

# Copie des fichiers de configuration Bind
docker cp configs/config_dns/named.conf entreprise_dns:/etc/bind/named.conf
docker cp configs/config_dns/named.conf.local entreprise_dns:/etc/bind/named.conf.local
docker cp configs/config_dns/named.conf.options entreprise_dns:/etc/bind/named.conf.options
docker cp configs/config_dns/zones/db.site.lan.internal entreprise_dns:/etc/bind/zones/db.site.lan.internal
docker cp configs/config_dns/zones/db.site.lan.external entreprise_dns:/etc/bind/zones/db.site.lan.external

# Lancement du script DNS
cat scripts/script_dns.sh | docker exec -i entreprise_dns bash &

echo "[INFO] Conteneur DNS créé et script de configuration lancé."

### --------------------------
### Création et lancement du serveur WEB
### --------------------------

# Build de l'image Docker Web
docker build -t web_server ./images/web

# Création du conteneur Web
docker create -it \
    --name entreprise_web \
    --hostname entreprise_web \
    --network none \
    --privileged \
    web_server

# Démarrage du conteneur Web
docker start entreprise_web

addNetnsList entreprise_web

# Copie des fichiers HTML et configuration Nginx (si besoin)
docker cp configs/config_web/public entreprise_web:/usr/share/nginx/html/public
docker cp configs/config_web/intranet entreprise_web:/usr/share/nginx/html/intranet
docker cp configs/config_web/nginx/nginx.conf entreprise_web:/etc/nginx/nginx.conf

# Lancement du script Web
cat scripts/script_web.sh | docker exec -i entreprise_web bash &

echo "[INFO] Conteneur Web créé et script de configuration lancé."
echo "[INFO] Les IP et la configuration réseau des conteneurs sont gérées dans leurs scripts respectifs."
