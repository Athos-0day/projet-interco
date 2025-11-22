#!/bin/bash

# Script de démarrage du serveur DNS de l'entreprise
# Usage: ./start_dns.sh

cd "$(dirname "$0")"

# Build de l'image Docker DNS
docker build -t dns_debian ./images/dns

# Création du conteneur DNS (network none pour gérer les interfaces manuellement)
docker create -it \
    --name entreprise_dns \
    --hostname entreprise_dns \
    --network none \
    --privileged \
    dns_debian

# Démarrage du conteneur
docker start entreprise_dns

# Fonction pour ajouter le namespace Docker
addNetnsList() {
    pid=$(docker inspect -f '{{.State.Pid}}' $1)
    sudo mkdir -p /var/run/netns/
    sudo ln -sfT /proc/$pid/ns/net /var/run/netns/$1
}

addNetnsList entreprise_dns

# Copie des fichiers de configuration Bind dans le conteneur
docker cp configs/config_dns/named.conf entreprise_dns:/etc/bind/named.conf
docker cp configs/config_dns/named.conf.local entreprise_dns:/etc/bind/named.conf.local
docker cp configs/config_dns/named.conf.options entreprise_dns:/etc/bind/named.conf.options
docker cp configs/config_dns/zones/db.site.lan.internal entreprise_dns:/etc/bind/zones/db.site.lan.internal
docker cp configs/config_dns/zones/db.site.lan.external entreprise_dns:/etc/bind/zones/db.site.lan.external


# Lancement du script DNS dans le conteneur
# Tout ce qui est IP, interface et port est géré dans script_dns.sh
cat scripts/script_dns.sh | docker exec -i entreprise_dns bash &

echo "[INFO] Conteneur DNS créé et script de configuration lancé."
echo "[INFO] Toutes les IP et configurations réseau sont gérées dans script_dns.sh"
