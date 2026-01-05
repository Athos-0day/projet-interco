#!/bin/bash

# Script permettant de connecter un conteneur au vpn
# Si on a le bon nombre d'arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <nom du conteneur>"
    exit 1
fi

# Nom du conteneur
CONTENEUR=$1

if ! docker ps | grep -qw "$CONTENEUR"; then
    echo "$CONTENEUR n'existe pas où n'est pas lancé"
    exit 0
fi

# On se place dans le répertoire du script
cd "$(dirname "$0")"

rm -rf configs/client_ovpn
docker cp entreprise_routeur_public:/home/client_ovpn configs/
docker cp configs/client_ovpn $CONTENEUR:/home

docker exec -it $CONTENEUR openvpn --config /home/client_ovpn/test.ovpn
