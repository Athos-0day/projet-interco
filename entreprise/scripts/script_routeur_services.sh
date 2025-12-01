#!/bin/bash

echo "[INFO] Configuration du routeur interne"

# Interfaces
# Côté services
ip link add name br0 type bridge
ip link set eth1 master br0
ip link set eth2 master br0
ip link set eth3 master br0
ip link set eth1 up
ip link set eth2 up
ip link set eth3 up
ip link set br0 up
ip addr add 192.168.49.17/28 dev br0

#Côté routeur
ip link add name br1 type bridge
ip link set eth3 master br0
ip link set eth4 master br0
ip link set eth3 up
ip link set eth4 up
ip link set br1 up
ip addr add 192.168.49.2/28 dev br1

# Routage
echo 1 > /proc/sys/net/ipv4/ip_forward

# Routes statiques
ip route add 192.168.49.32/28 via 192.168.49.3   # vers réseau utilisateurs
ip route add default via 192.168.49.1            # sortie vers le routeur public


echo "[INFO] Routeur interne configuré."
