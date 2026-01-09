#!/bin/bash

set -e

ADMIN_PASS="adminpass"
LDAP_IP="120.0.32.69/28"

ip link set lo up
ip link set eth0 up
ip addr add "$LDAP_IP" dev eth0
ip route add default via 120.0.32.65

# Résolution DNS interne et hostname local (évite les timeouts)
printf "nameserver 120.0.32.66\noptions timeout:1 attempts:1\n" > /etc/resolv.conf
printf "120.0.32.69\t%s\n" "$(hostname)" >> /etc/hosts


/etc/init.d/slapd start

echo "Starting LDAP server..."

# Attente du démarrage
until ldapsearch -x -H ldap://127.0.0.1 -b "dc=fai,dc=lab" >/dev/null 2>&1; do
  sleep 1
done

echo "LDAP started"

RADIUS_HASH=$(slappasswd -s "radiuspass")
ALICE_HASH=$(slappasswd -s "alicepass")
BOB_HASH=$(slappasswd -s "bobpass")

echo "Populating LDAP directory..."

cat <<EOF | ldapadd -x -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS"
dn: ou=clients,dc=fai,dc=lab
objectClass: organizationalUnit
ou: clients

dn: ou=svc,dc=fai,dc=lab
objectClass: organizationalUnit
ou: svc

dn: cn=radius,ou=svc,dc=fai,dc=lab
objectClass: organizationalRole
objectClass: simpleSecurityObject
cn: radius
description: RADIUS bind account
userPassword: ${RADIUS_HASH}

dn: uid=alice,ou=clients,dc=fai,dc=lab
objectClass: inetOrgPerson
cn: Alice
sn: Alice
uid: alice
userPassword: ${ALICE_HASH}

dn: uid=bob,ou=clients,dc=fai,dc=lab
objectClass: inetOrgPerson
cn: Bob
sn: Bob
uid: bob
userPassword: ${BOB_HASH}
EOF

add_client_user() {
  local uid="$1"
  local pass="$2"
  if [ -z "$uid" ] || [ -z "$pass" ]; then
    return
  fi
  if ldapsearch -x -H ldap://127.0.0.1 -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS" \
      -b "ou=clients,dc=fai,dc=lab" "(uid=$uid)" | grep -q "^dn: uid=${uid},"; then
    echo "LDAP user ${uid} already exists"
    return
  fi
  local hash
  hash=$(slappasswd -s "$pass")
  cat <<EOF | ldapadd -x -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS"
dn: uid=${uid},ou=clients,dc=fai,dc=lab
objectClass: inetOrgPerson
cn: ${uid}
sn: ${uid}
uid: ${uid}
userPassword: ${hash}
EOF
}

add_client_user "$CLIENT_A_USER" "$CLIENT_A_PASS"
add_client_user "$CLIENT_B_USER" "$CLIENT_B_PASS"

echo "LDAP up on 120.0.32.69:389 (base dc=fai,dc=lab)"
