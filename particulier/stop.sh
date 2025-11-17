#!/bin/bash

# On se place dans le répertoire du script
cd "$(dirname "$0")"

# On vérifie si l'identifiant du particulier'
if [ -z "$1" ]; then
    echo "Usage: $0 <id particulier>"
    echo "Il faut donner l'identifiant du particulier à supprimer"
    exit 1
fi
PARTICULIER_ID=$1

# On supprime les namespaces créé
sudo ip netns delete particulier${PARTICULIER_ID}_box_tmp

# On supprime les dockers du réseau
docker kill particulier${PARTICULIER_ID}_box
docker kill particulier${PARTICULIER_ID}_t1
docker kill particulier${PARTICULIER_ID}_t2
docker rm particulier${PARTICULIER_ID}_box
docker rm particulier${PARTICULIER_ID}_t1
docker rm particulier${PARTICULIER_ID}_t2

# On supprime les références vers les dockers supprimés
sudo find /var/run/netns -xtype l -delete


