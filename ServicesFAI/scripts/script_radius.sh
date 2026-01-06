#!/bin/bash

set -e

ip link set lo up
ip link set eth0 up
ip addr add 120.0.32.70/28 dev eth0
ip route add default via 120.0.32.65

# Résolution DNS interne pour éviter les timeouts
printf "nameserver 120.0.32.66\noptions timeout:1 attempts:1\n" > /etc/resolv.conf

# Démarrage FreeRADIUS (mode normal)
freeradius

echo "RADIUS up on 120.0.32.70:1812/1813"
