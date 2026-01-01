#!/bin/bash

# On se place dans le répertoire du script
cd "$(dirname "$0")"

# On supprime les namespaces créé
sudo ip netns delete fai_particulierSwitch

# On supprime les réseaux particuliers
../particulier/stop.sh A
../particulier/stop.sh B

../ServicesFAI/stop.sh A
../entreprise/stop.sh

# On supprime les dockers du réseau
# Kill et supprime un docker
#   $1: Nom du Docker
dockerRm() {
    docker kill $1
    docker rm $1
}

dockerRm fai_peParticulier
dockerRm fai_routeurToulouse
dockerRm fai_routeurLyon
dockerRm fai_routeurBordeaux
dockerRm fai_routeurParis
dockerRm fai_routeurBordure
dockerRm fai_peService
dockerRm fai_peEntreprise

# On supprime les références vers les dockers supprimés
sudo find /var/run/netns -xtype l -delete


