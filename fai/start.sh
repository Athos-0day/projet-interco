#!/bin/bash

# Script de démarrage du réseau FAI
# On passe en root



# On se place dans le répertoire du script
cd "$(dirname "$0")"

# Identifiants PPP pour les clients A/B (utilisés par les boxes)
PPP_A_USER="alice"
PPP_A_PASS="alicepass"
PPP_B_USER="bob"
PPP_B_PASS="bobpass"
CLIENT_A_IP="120.0.35.100"
CLIENT_B_IP="120.0.35.101"
CLIENT_A_DNS1="120.0.32.66"
CLIENT_B_DNS1="120.0.32.66"
CLIENT_A_DNS2="120.0.32.67"
CLIENT_B_DNS2="120.0.32.67"
CLIENT_A_RATE_DOWN="20000"
CLIENT_A_RATE_UP="5000"
CLIENT_B_RATE_DOWN="10000"
CLIENT_B_RATE_UP="2000"

# Construction des images dockers
docker build -q -t frr ./images/frr

# Creation et démarrage d'un docker
#   $1: Nom du Docker
#   $2: Nom de l'image utilisée
dockerStart() {
    local extra_args=""
    if [ "$1" = "fai_peParticulier" ]; then
        extra_args="-v /lib/modules:/lib/modules:ro"
    fi
    # commenté "> /dev/null 2>&1" si vous voulez le nom de l'image
    docker create -it --name $1 --hostname $1 --network none --privileged $extra_args $2 > /dev/null 2>&1 
    docker start $1

    # Ajout du namespace du container docker à la liste netns
    pid=$(docker inspect -f '{{.State.Pid}}' $1)
    sudo mkdir -p /var/run/netns/
    sudo ln -sfT /proc/$pid/ns/net /var/run/netns/$1
}

# Demarrage des dockers
dockerStart fai_peParticulier frr
dockerStart fai_routeurToulouse frr
dockerStart fai_routeurLyon frr
dockerStart fai_routeurBordeaux frr
dockerStart fai_routeurParis frr
dockerStart fai_routeurBordure frr
dockerStart fai_peService frr
dockerStart fai_peEntreprise frr


# ============== Connexion des dockers ==================

# Creation d'un lien ethernet virtuel entre 2 conteneur docker
#   $1: Nom du 1er Docker
#   $2: Nom de l'interface utilisée sur le 1er Docker
#   $3: Nom du 2nd Docker
#   $4: Nom de l'interface utilisée sur le 2nd Docker
addLink() {
    sudo ip netns exec $1 ip link add $2 type veth peer name $4 netns $3
}

# == RESEAU ACCES PARTICULIER ==

# Creation du switch particulier
sudo ip netns add fai_particulierSwitch 
sudo ip netns exec fai_particulierSwitch ip link add name br0 type bridge

# Connexion des réseaux particuliers au switch
../particulier/start.sh A "$PPP_A_USER" "$PPP_A_PASS" fai_particulierSwitch eth1
../particulier/start.sh B "$PPP_B_USER" "$PPP_B_PASS" fai_particulierSwitch eth2

# Connexion du switch au peParticulier
addLink fai_peParticulier eth1 fai_particulierSwitch eth0

# Connexions des interfaces au bridge
sudo ip netns exec fai_particulierSwitch ip link set eth0 master br0
sudo ip netns exec fai_particulierSwitch ip link set eth1 master br0
sudo ip netns exec fai_particulierSwitch ip link set eth2 master br0
sudo ip netns exec fai_particulierSwitch ip link set eth0 up
sudo ip netns exec fai_particulierSwitch ip link set eth1 up
sudo ip netns exec fai_particulierSwitch ip link set eth2 up
sudo ip netns exec fai_particulierSwitch ip link set br0 up

# Backbone
addLink fai_routeurToulouse eth0 fai_routeurBordeaux eth1
addLink fai_routeurToulouse eth1 fai_routeurLyon eth1
addLink fai_routeurToulouse eth2 fai_peParticulier eth0

addLink fai_routeurParis eth0 fai_routeurBordure eth1
addLink fai_routeurParis eth1 fai_peEntreprise eth0
addLink fai_routeurParis eth2 fai_peService eth0
addLink fai_routeurParis eth3 fai_routeurLyon eth0
addLink fai_routeurParis eth4 fai_routeurBordeaux eth0

# == RESEAU Service ==
CLIENT_A_USER="$PPP_A_USER" CLIENT_A_PASS="$PPP_A_PASS" \
CLIENT_A_IP="$CLIENT_A_IP" CLIENT_A_DNS1="$CLIENT_A_DNS1" CLIENT_A_DNS2="$CLIENT_A_DNS2" \
CLIENT_A_RATE_DOWN="$CLIENT_A_RATE_DOWN" CLIENT_A_RATE_UP="$CLIENT_A_RATE_UP" \
CLIENT_B_USER="$PPP_B_USER" CLIENT_B_PASS="$PPP_B_PASS" \
CLIENT_B_IP="$CLIENT_B_IP" CLIENT_B_DNS1="$CLIENT_B_DNS1" CLIENT_B_DNS2="$CLIENT_B_DNS2" \
CLIENT_B_RATE_DOWN="$CLIENT_B_RATE_DOWN" CLIENT_B_RATE_UP="$CLIENT_B_RATE_UP" \
../ServicesFAI/start.sh A
sudo ip netns exec servicesA_switch ip link set router1 name eth1 netns fai_peService

# == RESEAU Entreprise ==
#../entreprise/start.sh RH

#addLink entreprise_routeur_public eth0 fai_peEntreprise  eth1
#echo "Réseau Entreprise connecté"

# Ajouter les connexions Réseau d'acces Entreprise et réseau d'acces Service après le merge

# ================= CONFIG =======================


# On ajoute les fichiers de config aux dockers
docker cp configs/peParticulier/dhcpd.conf fai_peParticulier:/etc/dhcp/
docker cp configs/peParticulier/accel-ppp.conf fai_peParticulier:/etc/accel-ppp.conf

docker cp configs/peEntreprise/ospfd.conf fai_peEntreprise:/etc/frr/
docker cp configs/peParticulier/ospfd.conf fai_peParticulier:/etc/frr/
docker cp configs/peService/ospfd.conf fai_peService:/etc/frr/

docker cp configs/routeurBordeau/ospfd.conf fai_routeurBordeaux:/etc/frr/
docker cp configs/routeurBordure/ospfd.conf fai_routeurBordure:/etc/frr/
docker cp configs/routeurLyon/ospfd.conf fai_routeurLyon:/etc/frr/
docker cp configs/routeurParis/ospfd.conf fai_routeurParis:/etc/frr/
docker cp configs/routeurToulouse/ospfd.conf fai_routeurToulouse:/etc/frr/



# ================= Script de démarrage ======================
# Execution d'un script sur les dockers
docker exec -i fai_peEntreprise bash < scripts/peEntreprise.sh > /dev/null 2>&1 &
docker exec -i fai_peParticulier bash < scripts/peParticulier.sh > /dev/null 2>&1 &
docker exec -i fai_peService bash < scripts/peService.sh > /dev/null 2>&1 &
docker exec -i fai_routeurBordeaux bash < scripts/routeurBordeaux.sh > /dev/null 2>&1 &
docker exec -i fai_routeurBordure bash < scripts/routeurBordure.sh > /dev/null 2>&1 &
docker exec -i fai_routeurLyon bash < scripts/routeurLyon.sh > /dev/null 2>&1 &
docker exec -i fai_routeurParis bash < scripts/routeurParis.sh > /dev/null 2>&1 &
docker exec -i fai_routeurToulouse bash < scripts/routeurToulouse.sh > /dev/null 2>&1 &
echo "Le réseau FAI a été créé"

wait
echo "Tous les scripts ont été executé !"
