#!/bin/bash
# Script pour la gestion des interfaces de la box
echo "[INFO] Configuration du routeur bureau"
# Interface

# Côté machines
ip link add name br0 type bridge
ip link set eth1 master br0
ip link set eth2 master br0
ip link set eth1 up
ip link set eth2 up
ip link set br0 up
ip addr add 192.168.49.49/24 dev br0

# Côté routeur
ip link add name br1 type bridge
ip link set eth3 master br1
ip link set eth4 master br1
ip link set dev eth3 up
ip link set dev eth4 up
ip link set br1 up
ip addr add 192.168.49.34/24 dev br1

# Routage
echo 1 > /proc/sys/net/ipv4/ip_forward

# Ajout des routes
ip route add 192.168.49.16/28 via 192.168.49.2  # vers réseau services
ip route add default via 192.168.49.1            # sortie vers le routeur public

# On démarre le service DHCP
/etc/init.d/isc-dhcp-server start > /dev/null &

echo "[INFO] Routeur bureau configuré."

