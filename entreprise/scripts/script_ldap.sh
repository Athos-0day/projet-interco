#!/bin/bash

### --------------------------
### Configuration réseau
### --------------------------

LDAP_IP="192.168.49.21"
LDAP_NETMASK="/28"
LDAP_INTERFACE="eth0"

LDAP_ORGANISATION="Example Corp"
LDAP_DOMAIN="example.com"
LDAP_ADMIN_PASSWORD="adminpassword"
LDAP_BASE_DN="dc=example,dc=com"
LDIF_FILE="/etc/ldap/custom.ldif"
LDIF_FILE_USERS="/etc/ldap/users.ldif"

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



iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p udp --dport 389 -j ACCEPT
iptables -A INPUT -p tcp --dport 389 -j ACCEPT

### --------------------------
### Démarrage de OpenLDAP
### --------------------------

mkdir -p /var/run/slapd
chown openldap:openldap /var/run/slapd


slapd -h "ldap://0.0.0.0" &
sleep 10
ldapadd -x -D "cn=admin,$LDAP_BASE_DN" -w $LDAP_ADMIN_PASSWORD -f $LDIF_FILE
ldapadd -x -D "cn=admin,$LDAP_BASE_DN" -w $LDAP_ADMIN_PASSWORD -f $LDIF_FILE_USERS
ldapadd -x -H ldap://192.168.49.21 \
  -D "cn=admin,dc=example,dc=com" \
  -w $LDAP_ADMIN_PASSWORD \
  -f $LDIF_FILE_USERS
ip route add default via 192.168.49.17 

# On reset le password de jdoe à mdp
ldappasswd -H ldap://192.168.49.21 \
  -D "cn=admin,dc=example,dc=com" \
  -w "adminpassword" \
  -s "mdp" \
  "uid=jdoe,ou=People,dc=example,dc=com"

