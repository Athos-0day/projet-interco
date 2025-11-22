#!/bin/bash

### --------------------------
### Configuration réseau
### --------------------------

WEB_IP="192.168.49.20"
WEB_NETMASK="/24"
WEB_INTERFACE="eth0"

echo "[INFO] Attribution de l'adresse IP au serveur WEB : $WEB_IP$WEB_NETMASK"
ip addr add $WEB_IP$WEB_NETMASK dev $WEB_INTERFACE

echo "[INFO] Activation de l'interface $WEB_INTERFACE"
ip link set $WEB_INTERFACE up


### --------------------------
### Ouverture du port DNS (53)
### --------------------------

echo "[INFO] Ouverture du port WEB UDP/TCP 80"

iptables -A INPUT -p udp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT


### --------------------------
### Vérification des fichiers HTML et Nginx
### --------------------------

if [ ! -f /usr/share/nginx/html/public/index.html ]; then
    echo "[ERREUR] Fichier index.html public manquant."
    exit 1
fi

if [ ! -f /usr/share/nginx/html/intranet/index.html ]; then
    echo "[ERREUR] Fichier index.html intranet manquant."
    exit 1
fi

if [ ! -f /etc/nginx/nginx.conf ]; then
    echo "[ERREUR] Fichier de configuration nginx.conf manquant."
    exit 1
fi

echo "[INFO] Configuration Nginx OK"

### --------------------------
### Démarrage de Nginx
### --------------------------

echo "[INFO] Démarrage de Nginx en avant-plan"
/usr/sbin/nginx -g "daemon off;"

