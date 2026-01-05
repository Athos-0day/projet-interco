#!/bin/bash

# On se place dans le répertoire du script
cd "$(dirname "$0")"


# On supprime les namespaces créé
sudo ip netns delete entrepriseSecondaire_box_tmp

# On supprime les dockers du réseau
docker kill entrepriseSecondaire_box
docker kill entrepriseSecondaire_t1
docker kill entrepriseSecondaire_t2
docker rm entrepriseSecondaire_box
docker rm entrepriseSecondaire_t1
docker rm entrepriseSecondaire_t2

# On supprime les références vers les dockers supprimés
sudo find /var/run/netns -xtype l -delete


