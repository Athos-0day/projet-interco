#!/bin/bash

echo "[INFO] Configuration du serveur VoIP Asterisk"

# Attribution de l'IP fixe
VOIP_IP="192.168.49.19"
VOIP_INTERFACE="eth0"
ip addr add $VOIP_IP/28 dev $VOIP_INTERFACE
ip link set $VOIP_INTERFACE up

# Ouvrir les ports SIP et RTP
iptables -A INPUT -p udp --dport 5060 -j ACCEPT       
iptables -A INPUT -p udp --dport 10000:20000 -j ACCEPT  





# # Vérifier la configuration Asterisk
# asterisk -rx "core show settings" >/dev/null 2>&1
# if [ $? -ne 0 ]; then
#     echo "[ERROR] Configuration Asterisk invalide."
#     exit 1
# fi
#

ip route add default via 192.168.49.17            # sortie vers le routeur public
echo "[INFO] Démarrage d'Asterisk"
# Lancer Asterisk en avant-plan pour Docker
asterisk -f -U asterisk
