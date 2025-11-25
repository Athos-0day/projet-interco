#!/bin/bash

echo "[INFO] Configuration du routeur interne"

# Interfaces
# Côtés services
ip link add name br0 type bridge
ip link set eth1 master br0
ip link set eth2 master br0
ip link set eth1 up
ip link set eth2 up
ip link set br0 up
ip addr add 192.168.48.17/28 dev br0

#Côtés routeur
ip addr add 192.168.48.2/30 dev eth3
ip link set eth3 up

# Routage
echo 1 > /proc/sys/net/ipv4/ip_forward

# Routes statiques
ip route add 192.168.48.32/28 via 192.168.48.1
ip route add 192.168.48.0/32 via 192.168.48.1
ip route add default via 192.168.48.1

echo "[INFO] Routeur interne configuré."
