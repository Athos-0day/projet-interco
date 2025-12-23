#!/bin/bash

### --------------------------
### Récupération nom du service
### --------------------------
if [ "$#" -ne 1 ] && [ "$#" -ne 3 ]; then
    echo "Usage: $0 <id particulier> [<conteneur routeur FAI> <interface routeur FAI>]"
    exit 1
fi

# Nom du service
SERVICE_ID=$1

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
# Build de l'image du serveur VoIP
docker build -t voip_server ./images/voip

docker build -t openldap-custom ./images/ldap

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

# Création du conteneur serveur voip
docker create -it \
    --name entreprise_voip \
    --hostname entreprise_voip \
    --network none \
    --privileged \
    voip_server
    # -v $(pwd)/../configs/config_voip:/etc/asterisk \  # Mounting your configuration

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

# Création du conteneur routeur_bureau
docker create -it \
    --name entreprise_routeur_bureau_${SERVICE_ID} \
    --hostname entreprise_routeur_bureau_${SERVICE_ID} \
    --network none \
    --privileged \
    routeur

# Création du conteneur client1
docker create -it \
    --name entreprise_client1_${SERVICE_ID} \
    --hostname entreprise_client1_${SERVICE_ID} \
    --network none \
    --privileged \
    routeur

# Création du conteneur client2
docker create -it \
    --name entreprise_client2_${SERVICE_ID} \
    --hostname entreprise_client2_${SERVICE_ID} \
    --network none \
    --privileged \
    routeur

# Création du conteneur routeur public
docker create -it \
    --name entreprise_routeur_public \
    --hostname entreprise_routeur_public \
    --network none \
    --privileged \
    routeur


docker create -it \
  --name entreprise_ldap \
  -p 389:389 \
  -p 636:636 \
  -v ldap_data:/var/lib/ldap \
  -v ldap_config:/etc/ldap/slapd.d \
  openldap-custom

### --------------------------
### Démarrage des conteneurs
### --------------------------

# Démarrage du conteneur DNS
docker start entreprise_dns

# Démarrage du conteneur Web
docker start entreprise_web

# Démarrage du routeur services
docker start entreprise_routeur_services

# Démarrage du routeur bureau
docker start entreprise_routeur_bureau_${SERVICE_ID}

# Démarrage du client 1
docker start entreprise_client1_${SERVICE_ID}

# Démarrage du client 2
docker start entreprise_client2_${SERVICE_ID}

# Démarrage du routeur public
docker start entreprise_routeur_public

# Démarrage du serveur voip
docker start entreprise_voip

docker start entreprise_ldap

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
addNetnsList entreprise_routeur_bureau_${SERVICE_ID}
addNetnsList entreprise_client1_${SERVICE_ID}
addNetnsList entreprise_client2_${SERVICE_ID}
addNetnsList entreprise_routeur_public
addNetnsList entreprise_voip
addNetnsList entreprise_ldap


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

# Réseau services
addLink entreprise_dns eth0 entreprise_routeur_services eth1
addLink entreprise_web eth0 entreprise_routeur_services eth2
addLink entreprise_voip eth0 entreprise_routeur_services eth5

#Réseau central
addLink entreprise_routeur_services eth3 entreprise_routeur_public eth1
addLink entreprise_routeur_bureau_${SERVICE_ID} eth3 entreprise_routeur_public eth2

#Réseau machines
addLink entreprise_client1_${SERVICE_ID} eth0 entreprise_routeur_bureau_${SERVICE_ID} eth2
addLink entreprise_client2_${SERVICE_ID} eth0 entreprise_routeur_bureau_${SERVICE_ID} eth1

### --------------------------
### Copie des fichiers de configuration
### --------------------------

# Copie des fichiers de configuration Bind
docker cp configs/config_dns/named.conf entreprise_dns:/etc/bind/named.conf
docker cp configs/config_dns/named.conf.local entreprise_dns:/etc/bind/named.conf.local
docker cp configs/config_dns/named.conf.options entreprise_dns:/etc/bind/named.conf.options
docker exec entreprise_dns mkdir -p /etc/bind/zones
docker cp configs/config_dns/zones/db.site.lan.internal entreprise_dns:/etc/bind/zones/db.site.lan.internal
docker cp configs/config_dns/zones/db.site.lan.external entreprise_dns:/etc/bind/zones/db.site.lan.external

# Copie des fichiers HTML et configuration Nginx (si besoin)
docker cp configs/config_web/public entreprise_web:/usr/share/nginx/html/public
docker cp configs/config_web/intranet entreprise_web:/usr/share/nginx/html/intranet
docker cp configs/config_web/nginx/nginx.conf entreprise_web:/etc/nginx/nginx.conf

# Copie de la configuration DHCP 
docker cp configs/config_dhcp/dhcpd.conf entreprise_routeur_bureau_${SERVICE_ID}:/etc/dhcp/

# Copie de la configuration du serveur VoIP (Asterisk)

docker cp configs/config_voip/pjsip.conf entreprise_voip:/etc/asterisk/pjsip.conf
docker cp configs/config_voip/sip.conf entreprise_voip:/etc/asterisk/sip.conf
docker cp configs/config_voip/extensions.conf entreprise_voip:/etc/asterisk/extensions.conf

docker cp configs/config_voip/asterisk.conf entreprise_voip:/etc/asterisk/asterisk.conf
docker cp configs/config_voip/logger.conf entreprise_voip:/etc/asterisk/logger.conf
docker cp configs/config_voip/modules.conf entreprise_voip:/etc/asterisk/modules.conf
docker cp configs/config_voip/stasis.conf entreprise_voip:/etc/asterisk/stasis.conf
#
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
echo "[INFO] Conteneur Routeur Services créé et script de configuration lancé."

# Lancement du script Routeur Bureau
cat scripts/script_routeur_bureau.sh | docker exec -i entreprise_routeur_bureau_${SERVICE_ID} bash &
echo "[INFO] Conteneur Routeur Bureau créé et script de configuration lancé."

# Lancement des scripts Machine
cat scripts/script_client.sh | docker exec -i entreprise_client1_${SERVICE_ID} bash &
cat scripts/script_client.sh | docker exec -i entreprise_client2_${SERVICE_ID} bash &
echo "[INFO] Conteneur Client 1 et 2 créé et script de configuration lancé."

# Lancement du serveur voip
cat scripts/script_voip.sh | docker exec -i entreprise_voip bash &
echo "[INFO] Conteneur Serveur VOIP créé et script de configuration lancé."

# Lancement du routeur public
cat scripts/script_routeur_public.sh | docker exec -i entreprise_routeur_public bash &
echo "[INFO] Conteneur Routeur Public créé et script de configuration lancé."


echo "[INFO] Les IP et la configuration réseau des conteneurs sont gérées dans leurs scripts respectifs."
