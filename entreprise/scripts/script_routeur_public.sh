#!/bin/bash

echo "[INFO] Configuration du routeur public"

### --------------------------------------
### 1 — Configuration des interfaces
### --------------------------------------
ip link add name br0 type bridge
ip link set eth1 master br0
ip link set eth2 master br0
ip link set eth1 up
ip link set eth2 up
ip link set br0 up
ip addr add 192.168.49.1/28 dev br0   # réseau des routeurs

# IP publique (exemple) sur eth0
ip addr add 120.0.50.2/20 dev eth0
ip link set eth0 up

### --------------------------------------
### 2 — Activation du routage
### --------------------------------------
echo 1 > /proc/sys/net/ipv4/ip_forward

### --------------------------------------
### 3 — Routage statique
### --------------------------------------
ip route add 192.168.49.32/28 via 192.168.49.3   # routeur machines
ip route add 192.168.49.16/28 via 192.168.49.2   # routeur services


### ======================================
### 4 — FIREWALL : iptables
### ======================================

echo "[INFO] Configuration du firewall"

# Remise à zéro
iptables -F
iptables -t nat -F
iptables -X

# Stratégies par défaut
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT


# ---------------------------
# Autoriser le LAN interne
# ---------------------------
iptables -A INPUT -s 192.168.49.0/24 -j ACCEPT


# ---------------------------
# Autoriser loopback
# ---------------------------
iptables -A INPUT -i lo -j ACCEPT


# ---------------------------
# Autoriser trafic entrant EXTERNE :
# uniquement Web (80) et DNS (53)
# ---------------------------

PUBLIC_NET="120.0.48.0/20"
DNS_IP="192.168.49.18"
WEB_IP="192.168.49.20"

# Web HTTP
iptables -A FORWARD -p tcp -s $PUBLIC_NET -d $WEB_IP --dport 80 -j ACCEPT

# DNS (TCP + UDP)
iptables -A FORWARD -p tcp -s $PUBLIC_NET -d $DNS_IP --dport 53 -j ACCEPT
iptables -A FORWARD -p udp -s $PUBLIC_NET -d $DNS_IP --dport 53 -j ACCEPT

# REFUSER tout autre trafic d'Internet vers le LAN
iptables -A FORWARD -s $PUBLIC_NET -d 192.168.49.0/24 -j DROP


# ---------------------------
# NAT : masquerading
# Pour permettre au LAN de sortir vers Internet
# ---------------------------
iptables -t nat -A POSTROUTING -s 192.168.49.0/24 -o eth0 -j MASQUERADE


# ---------------------------
# Bloquer ICMP (ping) depuis l'extérieur
# ---------------------------
iptables -A INPUT -p icmp -s $PUBLIC_NET -j DROP
iptables -A FORWARD -p icmp -s $PUBLIC_NET -j DROP


echo "[INFO] Routeur public configuré avec firewall."
