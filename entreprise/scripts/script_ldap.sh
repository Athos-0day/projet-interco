#!/bin/bash

### --------------------------
### Configuration réseau
### --------------------------

LDAP_IP="192.168.49.21"
LDAP_NETMASK="/28"
LDAP_INTERFACE="eth0"

export LDAP_ORGANISATION="Example Corp"
export LDAP_DOMAIN="example.com"
export LDAP_ADMIN_PASSWORD="adminpassword"

echo "[INFO] Activation de l'interface $LDAP_INTERFACE"
ip link set $LDAP_INTERFACE up

echo "[INFO] Attribution de l'adresse IP au LDAP : $LDAP_IP$LDAP_NETMASK"
ip addr add $LDAP_IP$LDAP_NETMASK dev $LDAP_INTERFACE



### --------------------------
### Ouverture du port LDAP (389)
### --------------------------

echo "[INFO] Ouverture du port LDAP UDP/TCP 389"



echo "slapd slapd/no_configuration boolean false" | debconf-set-selections && \
echo "slapd slapd/domain string ${LDAP_DOMAIN}" | debconf-set-selections && \
echo "slapd shared/organization string ${LDAP_ORGANISATION}" | debconf-set-selections && \
echo "slapd slapd/password1 password ${LDAP_ADMIN_PASSWORD}" | debconf-set-selections && \
echo "slapd slapd/password2 password ${LDAP_ADMIN_PASSWORD}" | debconf-set-selections && \ 
dpkg-reconfigure -f noninteractive slapd





iptables -A INPUT -p udp --dport 389 -j ACCEPT
iptables -A INPUT -p tcp --dport 389 -j ACCEPT

### --------------------------
### Démarrage de OpenLDAP
### --------------------------
slapd -h "ldap://0.0.0.0" &


ip route add default via 192.168.49.17            

