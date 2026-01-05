#!/bin/bash

# Script permettant de lancer firefox dans un conteneur
# Si on a le bon nombre d'arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <nom du conteneur>"
    exit 0
fi

# Nom du conteneur
CONTENEUR=$1

if ! docker ps | grep -qw "$CONTENEUR"; then
    echo "$CONTENEUR n'existe pas où n'est pas lancé"
    exit 0
fi


# On se place dans le répertoire du script
cd "$(dirname "$0")"

sudo mkdir -p /etc/netns/$CONTENEUR
sudo docker cp $CONTENEUR:/etc/resolv.conf /etc/netns/$CONTENEUR/resolv.conf
sudo ip netns exec particulierA_t1 sudo -u paul firefox -p "tmp"
