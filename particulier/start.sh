#!/bin/bash

# Script de démarrage d'un réseau de particulier
# Usage: ./start.sh <id particulier> [<ppp_user> <ppp_pass> [<conteneur routeur FAI> <interface routeur FAI>]]
# Le réseau de particulier est composé d'une box et de 2 terminaux.
# La box utilise DHCP et NAT

# Si on a le bon nombre d'arguments
if [ "$#" -ne 1 ] && [ "$#" -ne 3 ] && [ "$#" -ne 5 ]; then
    echo "Usage: $0 <id particulier> [<ppp_user> <ppp_pass> [<conteneur routeur FAI> <interface routeur FAI>]]"
    exit 1
fi

# Nom du réseau
PARTICULIER_ID=$1

# Identifiants PPP pour la box
if [ "$#" -ge 3 ]; then
    PPP_USER="$2"
    PPP_PASS="$3"
fi

if [ -z "$PPP_USER" ]; then
    read -r -p "PPP username for particulier${PARTICULIER_ID}_box: " PPP_USER
fi
if [ -z "$PPP_PASS" ]; then
    read -r -s -p "PPP password for ${PPP_USER}: " PPP_PASS
    echo
fi

# On se place dans le répertoire du script
cd "$(dirname "$0")"

# Construction des images dockers
docker build -q -t dhcp_debian ./images/dhcp_debian

# Construction des dockers
docker create -it --name particulier${PARTICULIER_ID}_box --hostname particulier${PARTICULIER_ID}_box --network none --privileged dhcp_debian
docker create -it --name particulier${PARTICULIER_ID}_t1 --hostname particulier${PARTICULIER_ID}_t1 --network none --privileged dhcp_debian
docker create -it --name particulier${PARTICULIER_ID}_t2 --hostname particulier${PARTICULIER_ID}_t2 --network none --privileged dhcp_debian

# Demarrage des dockers
docker start particulier${PARTICULIER_ID}_box
docker start particulier${PARTICULIER_ID}_t1
docker start particulier${PARTICULIER_ID}_t2

# Ajout du namespace du container docker à la liste netns
# https://stackoverflow.com/questions/31265993/docker-networking-namespace-not-visible-in-ip-netns-list
# $1 : Nom du container
addNetnsList() {
    pid=$(docker inspect -f '{{.State.Pid}}' $1)
    sudo mkdir -p /var/run/netns/
    sudo ln -sfT /proc/$pid/ns/net /var/run/netns/$1
}

addNetnsList particulier${PARTICULIER_ID}_box
addNetnsList particulier${PARTICULIER_ID}_t1
addNetnsList particulier${PARTICULIER_ID}_t2

# ==== Creation de l'interface exterieure ETH0 de la box ====
# On créé un namespace pour stocker l'extrémité du lien non attribué
sudo ip netns add particulier${PARTICULIER_ID}_box_tmp
# On créé le lien veth
sudo ip netns exec particulier${PARTICULIER_ID}_box ip link add eth0 type veth peer name eth0 netns particulier${PARTICULIER_ID}_box_tmp
# Si le conteneur routeur FAI est donné en arguments on le connecte
if [ "$#" -eq 5 ]; then
    sudo ip netns exec particulier${PARTICULIER_ID}_box_tmp ip link set eth0 name $5 netns $4 
fi
# ========

# Creation d'un lien ethernet virtuel entre 2 conteneur docker
#   $1: Nom du 1er Docker
#   $2: Nom de l'interface utilisée sur le 1er Docker
#   $3: Nom du 2nd Docker
#   $4: Nom de l'interface utilisée sur le 2nd Docker
addLink() {
    sudo ip netns exec $1 ip link add $2 type veth peer name $4 netns $3
}
addLink particulier${PARTICULIER_ID}_box eth1 particulier${PARTICULIER_ID}_t1 eth0
addLink particulier${PARTICULIER_ID}_box eth2 particulier${PARTICULIER_ID}_t2 eth0


# On ajoute les fichiers de config aux dockers
docker cp configs/dhcpd.conf particulier${PARTICULIER_ID}_box:/etc/dhcp/

# Execution d'un script sur les dockers
cat scripts/script_box.sh | PPP_USER="$PPP_USER" PPP_PASS="$PPP_PASS" docker exec -i -e PPP_USER -e PPP_PASS particulier${PARTICULIER_ID}_box bash &
cat scripts/script_tx.sh | docker exec -i particulier${PARTICULIER_ID}_t1 bash  &
cat scripts/script_tx.sh | docker exec -i particulier${PARTICULIER_ID}_t2 bash  &

echo "Le réseau ${PARTICULIER_ID} a été créé"
