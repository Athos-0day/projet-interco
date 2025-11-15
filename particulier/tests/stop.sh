#!/bin/bash

# On se place dans le répertoire du script
cd "$(dirname "$0")"

# On supprime le réseau particulier
../stop.sh A

# On supprime les dockers du réseau
docker kill fai_particulierA
docker rm fai_particulierA

# On supprime les références vers les dockers supprimés
sudo find /var/run/netns -xtype l -delete


