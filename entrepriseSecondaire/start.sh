#!/bin/bash

# Script de démarrage d'un réseau de entrepriseSecondaire
# Usage: ./start.sh <id entrepriseSecondaire> [<conteneur routeur FAI> <interface routeur FAI>]
# Le réseau de l'entreprise secondaire est composé d'une box et de 2 terminaux.
# La box utilise DHCP et NAT

# Si on a le bon nombre d'arguments
if [ "$#" -ne 1 ] && [ "$#" -ne 3 ]; then
    echo "Usage: $0 [<conteneur routeur FAI> <interface routeur FAI>]"
    exit 1
fi


# On se place dans le répertoire du script
cd "$(dirname "$0")"

# Construction des images dockers
docker build -q -t dhcp_debian ./images/dhcp_debian

# Construction des dockers
docker create -it --name entrepriseSecondaire_box --hostname entrepriseSecondaire_box --network none --privileged dhcp_debian
docker create -it --name entrepriseSecondaire_t1 --hostname entrepriseSecondaire_t1 --network none --privileged dhcp_debian
docker create -it --name entrepriseSecondaire_t2 --hostname entrepriseSecondaire_t2 --network none --privileged dhcp_debian

# Demarrage des dockers
docker start entrepriseSecondaire_box
docker start entrepriseSecondaire_t1
docker start entrepriseSecondaire_t1

# Ajout du namespace du container docker à la liste netns
# https://stackoverflow.com/questions/31265993/docker-networking-namespace-not-visible-in-ip-netns-list
# $1 : Nom du container
addNetnsList() {
    pid=$(docker inspect -f '{{.State.Pid}}' $1)
    sudo mkdir -p /var/run/netns/
    sudo ln -sfT /proc/$pid/ns/net /var/run/netns/$1
}

addNetnsList entrepriseSecondaire_box
addNetnsList entrepriseSecondaire_t1
addNetnsList entrepriseSecondaire_t2

# ==== Creation de l'interface exterieure ETH0 de la box ====
# On créé un namespace pour stocker l'extrémité du lien non attribué
sudo ip netns add entrepriseSecondaire_box_tmp
# On créé le lien veth
sudo ip netns exec entrepriseSecondaire_box ip link add eth0 type veth peer name eth0 netns entrepriseSecondaire_box_tmp
# Si le conteneur routeur FAI est donné en arguments on le connecte
if [ "$#" -eq 3 ]; then
    sudo ip netns exec entrepriseSecondaire_box_tmp ip link set eth0 name $3 netns $2 
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
addLink entrepriseSecondaire_box eth1 entrepriseSecondaire_t1 eth0
addLink entrepriseSecondaire_box eth2 entrepriseSecondaire_t2 eth0


# On ajoute les fichiers de config aux dockers
docker cp configs/dhcpd.conf entrepriseSecondaire_box:/etc/dhcp/

# Execution d'un script sur les dockers
cat scripts/script_box.sh | docker exec -i entrepriseSecondaire_box bash &
cat scripts/script_tx.sh | docker exec -i entrepriseSecondaire_t1 bash  &
cat scripts/script_tx.sh | docker exec -i entrepriseSecondaire_t2 bash  &

echo "Le réseau entrepriseSecondaire a été créé"
