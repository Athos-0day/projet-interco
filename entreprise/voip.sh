#!/bin/bash

# Lance un client SIP pour le voip
APP_NAME="zoiper5"

if ! command -v $APP_NAME >/dev/null 2>&1; then
    echo "Erreur: $APP_NAME n'est pas installé ou pas dans le PATH."
    echo "Vous pouvez l'installer sur https://www.zoiper.com/en/voip-softphone/download/current"
    exit 1
fi

# Si on a le bon nombre d'arguments
if [ "$#" -ne 1 ]; then
    echo "Vous devez spécifier le conteneur dans lequel vous souhaitez lancez le client voip"
    echo "Usage: $0 <nom du conteneur>"
    echo "Voici la liste :"
    ip netns ls
    exit 1
fi

# Nom du conteneur
CONTENEUR=$1

if ! ip netns ls | grep -qw "$CONTENEUR"; then
    echo "Le namespace réseau de $CONTENEUR n'existe pas."
    echo "Voici la liste :"
    ip netns ls
    exit 1
fi

# On passe en root
if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

# On récupère le DNS
mkdir -p /etc/netns/$CONTENEUR
docker cp $CONTENEUR:/etc/resolv.conf /etc/netns/$CONTENEUR/resolv.conf > /dev/null

# On se place dans le répertoire du script
cd "$(dirname "$0")"

# On récupère le nom d'utilisateur
LOCAL_USER=$(logname)

# On lance le client SIP dans le namespace réseau du conteneur en temps qu'utilisitateur non root
ip netns exec $CONTENEUR sudo -u $LOCAL_USER env PULSE_SERVER=unix:/run/user/$(id -u "$LOCAL_USER")/pulse/native $APP_NAME -c configs/$APP_NAME/$CONTENEUR &




