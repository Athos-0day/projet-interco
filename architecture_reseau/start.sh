#!/bin/bash

# Script de démarrage d'un réseau fai
# Usage: ./start.sh <id fai> 
# Le réseau du fai est composé de 5 routeurs et de 3 switches.
# Les routeurs utilisent DHCP


# Si on a le bon nombre d'arguments
if [ "$#" -ne 1 ] ; then #&& [ "$#" -ne 3 ]
    echo "Usage: $0 <id fai> "
    exit 1
fi


# Nom du réseau
FAI_ID=$1

# On se place dans le répertoire du script
cd "$(dirname "$0")"

# Construction des images dockers
docker build -t dhcp_debian ./images/dhcp_debian

# Construction des dockers
docker create -it --name routeur_${FAI_ID}_central --hostname outeur_${FAI_ID}_central --network none --privileged dhcp_debian
docker create -it --name routeur_${FAI_ID}_intranet --hostname outeur_${FAI_ID}_intranet --network none --privileged dhcp_debian
docker create -it --name routeur_${FAI_ID}_ville_1 --hostname outeur_${FAI_ID}_ville_1 --network none --privileged dhcp_debian
docker create -it --name routeur_${FAI_ID}_ville_2 --hostname outeur_${FAI_ID}_ville_2 --network none --privileged dhcp_debian
docker create -it --name routeur_${FAI_ID}_dns --hostname outeur_${FAI_ID}_dns --network none --privileged dhcp_debian

# demarrage des dockers
docker start routeur_${FAI_ID}_central
docker start routeur_${FAI_ID}_intranet
docker start routeur_${FAI_ID}_ville_1
docker start routeur_${FAI_ID}_ville_2
docker start routeur_${FAI_ID}_dns

# Ajout du namespace du container docker à la liste netns
# https://stackoverflow.com/questions/31265993/docker-networking-namespace-not-visible-in-ip-netns-list
# $1 : Nom du container
addNetnsList() {
    pid=$(docker inspect -f '{{.State.Pid}}' $1)
    sudo mkdir -p /var/run/netns/
    sudo ln -sfT /proc/$pid/ns/net /var/run/netns/$1
}

addNetnsList routeur_${FAI_ID}_central
addNetnsList routeur_${FAI_ID}_intranet
addNetnsList routeur_${FAI_ID}_ville_1
addNetnsList routeur_${FAI_ID}_ville_2
addNetnsList routeur_${FAI_ID}_dns

# ==== Creation de l'interface exterieure ETH0 du routeur intranet ====
# On créé un namespace pour stocker l'extrémité du lien non attribué
sudo ip netns add routeur_${FAI_ID}_intranet_tmp
# On créé le lien veth
sudo ip netns exec routeur_${FAI_ID}_intranet ip link add eth0 type veth peer name eth0 netns routeur_${FAI_ID}_intranet_tmp
# Si le conteneur routeur FAI est donné en arguments on le connecte # argument pas encore ok 
if [ "$#" -eq 3 ]; then
    sudo ip netns exec routeur_${FAI_ID}_intranet_tmp ip link set eth0 name $3 netns $2 
fi

# ==== Creation de l'interface exterieure ETH0 du routeur ville 1 ====
# On créé un namespace pour stocker l'extrémité du lien non attribué
sudo ip netns add routeur_${FAI_ID}_ville_1_tmp
# On créé le lien veth
sudo ip netns exec routeur_${FAI_ID}_ville_1 ip link add eth0 type veth peer name eth0 netns routeur_${FAI_ID}_ville_1_tmp
# Si le conteneur routeur FAI est donné en arguments on le connecte # argument pas encore ok 
if [ "$#" -eq 3 ]; then
    sudo ip netns exec routeur_${FAI_ID}_ville_1_tmp ip link set eth0 name $3 netns $2 
fi

# ==== Creation de l'interface exterieure ETH0 du routeur ville 2 ====
# On créé un namespace pour stocker l'extrémité du lien non attribué
sudo ip netns add routeur_${FAI_ID}_ville_2_tmp
# On créé le lien veth
sudo ip netns exec routeur_${FAI_ID}_ville_2 ip link add eth0 type veth peer name eth0 netns routeur_${FAI_ID}_ville_2_tmp
# Si le conteneur routeur FAI est donné en arguments on le connecte # argument pas encore ok 
if [ "$#" -eq 3 ]; then
    sudo ip netns exec routeur_${FAI_ID}_ville_2_tmp ip link set eth0 name $3 netns $2 
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


addLink routeur_${FAI_ID}_central eth1 routeur_${FAI_ID}_intranet eth0
addLink routeur_${FAI_ID}_central eth2 routeur_${FAI_ID}_ville_1 eth2
addLink routeur_${FAI_ID}_central eth2 routeur_${FAI_ID}_ville_2 eth2
addLink routeur_${FAI_ID}_central eth3 routeur_${FAI_ID}_dns eth0


# On ajoute les fichiers de config aux dockers
docker cp configs/central/dhcpd.conf routeur_${FAI_ID}_central:/etc/dhcp/
docker cp configs/intranet/dhcpd.conf routeur_${FAI_ID}_intranet:/etc/dhcp/
docker cp configs/ville/dhcpd.conf routeur_${FAI_ID}_ville_1:/etc/dhcp/
docker cp configs/ville/dhcpd.conf routeur_${FAI_ID}_ville_2:/etc/dhcp/
docker cp configs/dns/dhcpd.conf routeur_${FAI_ID}_dns:/etc/dhcp/


# Execution d'un script sur les dockers
cat scripts/routeur_central.sh | docker exec -i routeur_${FAI_ID}_central bash &
cat scripts/routeur_intranet.sh | docker exec -i routeur_${FAI_ID}_intranet bash  &
cat scripts/routeur_ville.sh 1 | docker exec -i routeur_${FAI_ID}_ville_1 bash  &
cat scripts/routeur_ville.sh 2 | docker exec -i routeur_${FAI_ID}_ville_2 bash  &
cat scripts/routeur_dns.sh | docker exec -i routeur_${FAI_ID}_dns bash  &


echo "Le réseau ${FAI_ID} a été créé"