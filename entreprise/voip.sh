#!/bin/bash

# On se place dans le répertoire du script
cd "$(dirname "$0")"

if [ ! -f "linphone.AppImage" ]; then
    echo "Téléchargement de linphone..."
    wget -O linphone.AppImage https://download.linphone.org/releases/linux/app/Linphone-5.3.0.AppImage
    chmod "u+x" linphone.AppImage
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

# Fichier config
HOME2=$(pwd)/configs/linphone/$CONTENEUR
sudo -u $LOCAL_USER mkdir -p $HOME2/.local/share/

# On lance le client SIP dans le namespace réseau du conteneur en temps qu'utilisitateur non root
ip netns exec $CONTENEUR \
    sudo -u $LOCAL_USER \
    env PULSE_SERVER=unix:/run/user/$(id -u "$LOCAL_USER")/pulse/native \
    env XDG_RUNTIME_DIR=/run/user/$(id -u "$LOCAL_USER") \
    env HOME=$HOME2 \
    dbus-run-session -- \
    ./linphone.AppImage




