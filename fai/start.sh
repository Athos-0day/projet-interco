#!/bin/bash

# Script de démarrage du réseau FAI
# Usage: sudo ./start.sh
if [[ $EUID -ne 0 ]]; then
    echo "Usage: sudo ./start.sh"
    exit 1
fi



# On se place dans le répertoire du script
cd "$(dirname "$0")"

# Construction des images dockers
docker build -q -t frr ./images/frr

# Creation et démarrage d'un docker
#   $1: Nom du Docker
#   $2: Nom de l'image utilisée
dockerStart() {
    docker create -it --name $1 --hostname $1 --network none --privileged $2
    docker start $1

    # Ajout du namespace du container docker à la liste netns
    pid=$(docker inspect -f '{{.State.Pid}}' $1)
    sudo mkdir -p /var/run/netns/
    sudo ln -sfT /proc/$pid/ns/net /var/run/netns/$1
}

# Demarrage des dockers
dockerStart fai_peParticulier frr
dockerStart fai_routeurToulouse frr
dockerStart fai_routeurLyon frr
dockerStart fai_routeurBordeaux frr
dockerStart fai_routeurParis frr
dockerStart fai_routeurBordure frr
dockerStart fai_peService frr
dockerStart fai_peEntreprise frr


# ============== Connexion des dockers ==================

# Creation d'un lien ethernet virtuel entre 2 conteneur docker
#   $1: Nom du 1er Docker
#   $2: Nom de l'interface utilisée sur le 1er Docker
#   $3: Nom du 2nd Docker
#   $4: Nom de l'interface utilisée sur le 2nd Docker
addLink() {
    sudo ip netns exec $1 ip link add $2 type veth peer name $4 netns $3
}

# == RESEAU ACCES PARTICULIER ==

# Creation du switch particulier
ip netns add fai_particulierSwitch 
ip netns exec fai_particulierSwitch ip link add name br0 type bridge

# Connexion des réseaux particuliers au switch
../particulier/start.sh A fai_particulierSwitch eth1
../particulier/start.sh B fai_particulierSwitch eth2

# Connexion du switch au peParticulier
addLink fai_peParticulier eth1 fai_particulierSwitch eth0

# Connexions des interfaces au bridge
ip netns exec fai_particulierSwitch ip link set eth0 master br0
ip netns exec fai_particulierSwitch ip link set eth1 master br0
ip netns exec fai_particulierSwitch ip link set eth2 master br0
ip netns exec fai_particulierSwitch ip link set eth0 up
ip netns exec fai_particulierSwitch ip link set eth1 up
ip netns exec fai_particulierSwitch ip link set eth2 up
ip netns exec fai_particulierSwitch ip link set br0 up

# Backbone
addLink fai_routeurToulouse eth0 fai_routeurBordeaux eth1
addLink fai_routeurToulouse eth1 fai_routeurLyon eth1
addLink fai_routeurToulouse eth2 fai_peParticulier eth0

addLink fai_routeurParis eth0 fai_routeurBordure eth1
addLink fai_routeurParis eth1 fai_peEntreprise eth0
addLink fai_routeurParis eth2 fai_peService eth0
addLink fai_routeurParis eth3 fai_routeurLyon eth0
addLink fai_routeurParis eth4 fai_routeurBordeaux eth0

# Ajouter les connexions Réseau d'acces Entreprise et réseau d'acces Service après le merge

# ================= CONFIG =======================


# On ajoute les fichiers de config aux dockers
docker cp configs/dhcpd.conf fai_peParticulier:/etc/dhcp/
docker cp scripts/routeurBordeau/ospfd.conf fai_routeurBordeaux:/etc/frr/

# ================= Script de démarrage ======================
# Execution d'un script sur les dockers
docker exec -i fai_peEntreprise bash < scripts/peEntreprise.sh &
docker exec -i fai_peParticulier bash < scripts/peParticulier.sh &
docker exec -i fai_peService bash < scripts/peService.sh &
docker exec -i fai_routeurBordeaux bash < scripts/routeurBordeaux.sh &
docker exec -i fai_routeurBordure bash < scripts/routeurBordure.sh &
docker exec -i fai_routeurLyon bash < scripts/routeurLyon.sh &
docker exec -i fai_routeurParis bash < scripts/routeurParis.sh &
docker exec -i fai_routeurToulouse bash < scripts/routeurToulouse.sh &



echo "Le réseau FAI a été créé"