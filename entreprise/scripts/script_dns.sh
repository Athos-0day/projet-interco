#!/bin/bash

### --------------------------
### Configuration réseau
### --------------------------

DNS_IP="192.168.49.18"
DNS_NETMASK="/24"
DNS_INTERFACE="eth0"

echo "[INFO] Attribution de l'adresse IP au DNS : $DNS_IP$DNS_NETMASK"
ip addr add $DNS_IP$DNS_NETMASK dev $DNS_INTERFACE

echo "[INFO] Activation de l'interface $DNS_INTERFACE"
ip link set $DNS_INTERFACE up


### --------------------------
### Ouverture du port DNS (53)
### --------------------------

echo "[INFO] Ouverture du port DNS UDP/TCP 53"

iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT


### --------------------------
### Vérification des fichiers Bind
### --------------------------

echo "[INFO] Vérification de la configuration Bind"
named-checkconf /etc/bind/named.conf

if [ $? -ne 0 ]; then
    echo "[ERREUR] Configuration Bind invalide."
    exit 1
fi


### --------------------------
### Démarrage de Bind9
### --------------------------

echo "[INFO] Démarrage de Bind9"

# Bind en avant-plan pour Docker
/usr/sbin/named -c /etc/bind/named.conf -f
