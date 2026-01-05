#!/bin/bash

# Script de creation d'une architecture de test d'un réseau de particulier
# Usage: ./test.sh

# Nom du réseau
PARTICULIER_ID="A"

# On se place dans le répertoire du script
cd "$(dirname "$0")"

# Construction des images dockers
docker build -q -t dhcp_debian ../images/dhcp_debian

# Construction des dockers
docker create -it --name fai_particulierA --hostname fai_particulierA --network none --privileged dhcp_debian

# Demarrage des dockers
docker start fai_particulierA

# Ajout du namespace du container docker à la liste netns
# https://stackoverflow.com/questions/31265993/docker-networking-namespace-not-visible-in-ip-netns-list
# $1 : Nom du container
addNetnsList() {
    pid=$(docker inspect -f '{{.State.Pid}}' $1)
    sudo mkdir -p /var/run/netns/
    sudo ln -sfT /proc/$pid/ns/net /var/run/netns/$1
}

addNetnsList fai_particulierA

# Creation du réseau particulierA
../start.sh A fai_particulierA eth1

# On ajoute les fichiers de config aux dockers
docker cp configs/dhcpd.conf fai_particulierA:/etc/dhcp/

# Execution d'un script sur les dockers
cat scripts/script_routeur.sh | docker exec -i fai_particulierA bash &

echo "Le réseau de test a été créé"