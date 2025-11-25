#!/bin/bash

cd "$(dirname "$0")"

### --------------------------
### Build des images Docker
### --------------------------

# Build de l'image Docker DNS
docker build -t dns_debian ./images/dns
# Build de l'image Docker Web
docker build -t web_server ./images/web
# Buid de l'image du routeur
docker build -t routeur ./images/routeur

### --------------------------
### Création des conteneurs
### --------------------------

# Création du conteneur dns
docker create -it \
    --name entreprise_dns \
    --hostname entreprise_dns \
    --network none \
    --privileged \
    dns_debian

# Création du conteneur web 
docker create -it \
    --name entreprise_web \
    --hostname entreprise_web \
    --network none \
    --privileged \
    web_server

# Création du conteneur routeur_services
docker create -it \
    --name entreprise_routeur_services \
    --hostname entreprise_routeur_services \
    --network none \
    --privileged \
    routeur

### --------------------------
### Démarrage des conteneurs
### --------------------------

# Démarrage du conteneur DNS
docker start entreprise_dns

# Démarrage du conteneur Web
docker start entreprise_web

# Démarrage du routeur services
docker start entreprise_routeur_services

### --------------------------
### Ajouter namespace_docker
### --------------------------

# Fonction pour ajouter le namespace Docker
addNetnsList() {
    pid=$(docker inspect -f '{{.State.Pid}}' $1)
    sudo mkdir -p /var/run/netns/
    sudo ln -sf /proc/$pid/ns/net /var/run/netns/$1
}

addNetnsList entreprise_dns
addNetnsList entreprise_web
addNetnsList entreprise_routeur_services

### --------------------------
### Création des liens
### --------------------------

# Creation d'un lien ethernet virtuel entre 2 conteneur docker
#   $1: Nom du 1er Docker
#   $2: Nom de l'interface utilisée sur le 1er Docker
#   $3: Nom du 2nd Docker
#   $4: Nom de l'interface utilisée sur le 2nd Docker
addLink() {
    sudo ip netns exec $1 ip link add $2 type veth peer name $4 netns $3
}
addLink entreprise_dns eth0 entreprise_routeur_services eth1
addLink entreprise_web eth0 entreprise_routeur_services eth2

### --------------------------
### Copie des fichiers de configuration
### --------------------------

# Copie des fichiers de configuration Bind
docker cp configs/config_dns/named.conf entreprise_dns:/etc/bind/named.conf
docker cp configs/config_dns/named.conf.local entreprise_dns:/etc/bind/named.conf.local
docker cp configs/config_dns/named.conf.options entreprise_dns:/etc/bind/named.conf.options
docker cp configs/config_dns/zones/db.site.lan.internal entreprise_dns:/etc/bind/zones/db.site.lan.internal
docker cp configs/config_dns/zones/db.site.lan.external entreprise_dns:/etc/bind/zones/db.site.lan.external

# Copie des fichiers HTML et configuration Nginx (si besoin)
docker cp configs/config_web/public entreprise_web:/usr/share/nginx/html/public
docker cp configs/config_web/intranet entreprise_web:/usr/share/nginx/html/intranet
docker cp configs/config_web/nginx/nginx.conf entreprise_web:/etc/nginx/nginx.conf

### --------------------------
### Lancement des scripts
### --------------------------

# Lancement du script DNS
cat scripts/script_dns.sh | docker exec -i entreprise_dns bash &
echo "[INFO] Conteneur DNS créé et script de configuration lancé."

# Lancement du script Web
cat scripts/script_web.sh | docker exec -i entreprise_web bash &
echo "[INFO] Conteneur Web créé et script de configuration lancé."

# Lancement du script Routeur Services
cat scripts/script_routeur_services.sh | docker exec -i entreprise_routeur_services bash &
echo "[INFO] Conteneur Routeur Services créé et script de configuratuon lancé."

echo "[INFO] Les IP et la configuration réseau des conteneurs sont gérées dans leurs scripts respectifs."
