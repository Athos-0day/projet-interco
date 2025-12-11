#!/bin/bash

# On se place dans le répertoire du script
cd "$(dirname "$0")"

# On vérifie si l'identifiant du fai'
if [ -z "$1" ]; then
    echo "Usage: $0 <id fai>"
    echo "Il faut donner l'identifiant du fai à supprimer"
    exit 1
fi



FAI_ID=$1

# On supprime les namespaces créé
sudo ip netns delete routeur_${FAI_ID}_ville_1_tmp
sudo ip netns delete routeur_${FAI_ID}_ville_2_tmp
sudo ip netns delete routeur_${FAI_ID}_intranet_tmp

# On supprime les dockers du réseau

docker kill routeur_${FAI_ID}_central
docker kill routeur_${FAI_ID}_intranet
docker kill routeur_${FAI_ID}_ville_1
docker kill routeur_${FAI_ID}_ville_2
docker kill routeur_${FAI_ID}_dns

docker rm routeur_${FAI_ID}_central
docker rm routeur_${FAI_ID}_intranet
docker rm routeur_${FAI_ID}_ville_1
docker rm routeur_${FAI_ID}_ville_2
docker rm routeur_${FAI_ID}_dns

# On supprime les références vers les dockers supprimés
sudo find /var/run/netns -xtype l -delete
