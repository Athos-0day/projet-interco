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

ensure_radius_schema() {
  if ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=schema,cn=config" "(cn=fai-radius)" 2>/dev/null | grep -q "^cn: fai-radius$"; then
    if ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=fai-radius,cn=schema,cn=config" 2>/dev/null | grep -q "faiRateLimit"; then
      return
    fi
    cat <<'EOF' | ldapmodify -Y EXTERNAL -H ldapi:///
dn: cn=fai-radius,cn=schema,cn=config
changetype: modify
add: olcAttributeTypes
olcAttributeTypes: ( 1.3.6.1.4.1.55555.1.5 NAME 'faiRateLimitDown' DESC 'FAI rate limit down (kbit/s)' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
-
add: olcAttributeTypes
olcAttributeTypes: ( 1.3.6.1.4.1.55555.1.6 NAME 'faiRateLimitUp' DESC 'FAI rate limit up (kbit/s)' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
-
add: olcObjectClasses
olcObjectClasses: ( 1.3.6.1.4.1.55555.1.7 NAME 'faiSubscriberBw' DESC 'FAI subscriber bandwidth attributes' AUXILIARY MAY ( faiRateLimitDown $ faiRateLimitUp ) )
-
add: olcAttributeTypes
olcAttributeTypes: ( 1.3.6.1.4.1.55555.1.8 NAME 'faiRateLimit' DESC 'FAI rate limit string (down/up)' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
-
add: olcObjectClasses
olcObjectClasses: ( 1.3.6.1.4.1.55555.1.9 NAME 'faiSubscriberBwExt' DESC 'FAI subscriber bandwidth string' AUXILIARY MAY ( faiRateLimit ) )
EOF
    return
  fi
  cat <<'EOF' | ldapadd -Y EXTERNAL -H ldapi:///
dn: cn=fai-radius,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: fai-radius
olcAttributeTypes: ( 1.3.6.1.4.1.55555.1.1 NAME 'faiFramedIPAddress' DESC 'FAI Framed-IP-Address' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
olcAttributeTypes: ( 1.3.6.1.4.1.55555.1.2 NAME 'faiPrimaryDNS' DESC 'FAI Primary DNS' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
olcAttributeTypes: ( 1.3.6.1.4.1.55555.1.3 NAME 'faiSecondaryDNS' DESC 'FAI Secondary DNS' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
olcAttributeTypes: ( 1.3.6.1.4.1.55555.1.5 NAME 'faiRateLimitDown' DESC 'FAI rate limit down (kbit/s)' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
olcAttributeTypes: ( 1.3.6.1.4.1.55555.1.6 NAME 'faiRateLimitUp' DESC 'FAI rate limit up (kbit/s)' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
olcAttributeTypes: ( 1.3.6.1.4.1.55555.1.8 NAME 'faiRateLimit' DESC 'FAI rate limit string (down/up)' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
olcObjectClasses: ( 1.3.6.1.4.1.55555.1.4 NAME 'faiSubscriber' DESC 'FAI subscriber RADIUS attributes' AUXILIARY MAY ( faiFramedIPAddress $ faiPrimaryDNS $ faiSecondaryDNS ) )
olcObjectClasses: ( 1.3.6.1.4.1.55555.1.7 NAME 'faiSubscriberBw' DESC 'FAI subscriber bandwidth attributes' AUXILIARY MAY ( faiRateLimitDown $ faiRateLimitUp ) )
olcObjectClasses: ( 1.3.6.1.4.1.55555.1.9 NAME 'faiSubscriberBwExt' DESC 'FAI subscriber bandwidth string' AUXILIARY MAY ( faiRateLimit ) )
EOF
}

ensure_radius_schema

RADIUS_HASH=$(slappasswd -s "radiuspass")

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
EOF

add_client_user() {
  local uid="$1"
  local pass="$2"
  local framed_ip="$3"
  local dns1="$4"
  local dns2="$5"
  local rate_down="$6"
  local rate_up="$7"
  if [ -z "$uid" ] || [ -z "$pass" ]; then
    return
  fi
  if [ -z "$framed_ip" ] || [ -z "$dns1" ]; then
    echo "LDAP user ${uid} missing framed IP or DNS; skipping"
    return
  fi
  if ldapsearch -x -H ldap://127.0.0.1 -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS" \
      -b "ou=clients,dc=fai,dc=lab" "(uid=$uid)" | grep -q "^dn: uid=${uid},"; then
    if ! ldapsearch -x -H ldap://127.0.0.1 -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS" \
        -b "ou=clients,dc=fai,dc=lab" "(&(uid=$uid)(objectClass=faiSubscriber))" | grep -q "^dn: uid=${uid},"; then
      cat <<EOF | ldapmodify -x -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS"
dn: uid=${uid},ou=clients,dc=fai,dc=lab
changetype: modify
add: objectClass
objectClass: faiSubscriber
EOF
    fi
    if ! ldapsearch -x -H ldap://127.0.0.1 -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS" \
        -b "ou=clients,dc=fai,dc=lab" "(&(uid=$uid)(objectClass=faiSubscriberBw))" | grep -q "^dn: uid=${uid},"; then
      cat <<EOF | ldapmodify -x -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS"
dn: uid=${uid},ou=clients,dc=fai,dc=lab
changetype: modify
add: objectClass
objectClass: faiSubscriberBw
EOF
    fi
    if ! ldapsearch -x -H ldap://127.0.0.1 -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS" \
        -b "ou=clients,dc=fai,dc=lab" "(&(uid=$uid)(objectClass=faiSubscriberBwExt))" | grep -q "^dn: uid=${uid},"; then
      cat <<EOF | ldapmodify -x -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS"
dn: uid=${uid},ou=clients,dc=fai,dc=lab
changetype: modify
add: objectClass
objectClass: faiSubscriberBwExt
EOF
    fi
    cat <<EOF | ldapmodify -x -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS"
dn: uid=${uid},ou=clients,dc=fai,dc=lab
changetype: modify
replace: userPassword
userPassword: $(slappasswd -s "$pass")
replace: faiFramedIPAddress
faiFramedIPAddress: ${framed_ip}
replace: faiPrimaryDNS
faiPrimaryDNS: ${dns1}
EOF
    if [ -n "$dns2" ]; then
      cat <<EOF | ldapmodify -x -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS"
dn: uid=${uid},ou=clients,dc=fai,dc=lab
changetype: modify
replace: faiSecondaryDNS
faiSecondaryDNS: ${dns2}
EOF
    fi
    if [ -n "$rate_down" ] && [ -n "$rate_up" ]; then
      cat <<EOF | ldapmodify -x -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS"
dn: uid=${uid},ou=clients,dc=fai,dc=lab
changetype: modify
replace: faiRateLimitDown
faiRateLimitDown: ${rate_down}
replace: faiRateLimitUp
faiRateLimitUp: ${rate_up}
replace: faiRateLimit
faiRateLimit: ${rate_down}/${rate_up}
EOF
    fi
    echo "LDAP user ${uid} updated"
    return
  fi
  local hash
  hash=$(slappasswd -s "$pass")
  local secondary_line=""
  local rate_line=""
  if [ -n "$dns2" ]; then
    secondary_line="faiSecondaryDNS: ${dns2}"
  fi
  local rate_down_line=""
  local rate_up_line=""
  if [ -n "$rate_down" ] && [ -n "$rate_up" ]; then
    rate_down_line="faiRateLimitDown: ${rate_down}"
    rate_up_line="faiRateLimitUp: ${rate_up}"
    rate_line="faiRateLimit: ${rate_down}/${rate_up}"
  fi
  cat <<EOF | ldapadd -x -D "cn=admin,dc=fai,dc=lab" -w "$ADMIN_PASS"
dn: uid=${uid},ou=clients,dc=fai,dc=lab
objectClass: inetOrgPerson
objectClass: faiSubscriber
objectClass: faiSubscriberBw
objectClass: faiSubscriberBwExt
cn: ${uid}
sn: ${uid}
uid: ${uid}
userPassword: ${hash}
faiFramedIPAddress: ${framed_ip}
faiPrimaryDNS: ${dns1}
${secondary_line}
${rate_down_line}
${rate_up_line}
${rate_line}
EOF
}

DEFAULT_A_USER="alice"
DEFAULT_A_PASS="alicepass"
DEFAULT_A_IP="120.0.35.100"
DEFAULT_A_DNS1="120.0.32.66"
DEFAULT_A_DNS2=""
DEFAULT_B_USER="bob"
DEFAULT_B_PASS="bobpass"
DEFAULT_B_IP="120.0.35.101"
DEFAULT_B_DNS1="120.0.32.66"
DEFAULT_B_DNS2=""
DEFAULT_A_RATE_DOWN="20000"
DEFAULT_A_RATE_UP="5000"
DEFAULT_B_RATE_DOWN="10000"
DEFAULT_B_RATE_UP="2000"

CLIENT_A_USER="${CLIENT_A_USER:-$DEFAULT_A_USER}"
CLIENT_A_PASS="${CLIENT_A_PASS:-$DEFAULT_A_PASS}"
CLIENT_A_IP="${CLIENT_A_IP:-$DEFAULT_A_IP}"
CLIENT_A_DNS1="${CLIENT_A_DNS1:-$DEFAULT_A_DNS1}"
CLIENT_A_DNS2="${CLIENT_A_DNS2:-$DEFAULT_A_DNS2}"
CLIENT_A_RATE_DOWN="${CLIENT_A_RATE_DOWN:-$DEFAULT_A_RATE_DOWN}"
CLIENT_A_RATE_UP="${CLIENT_A_RATE_UP:-$DEFAULT_A_RATE_UP}"

CLIENT_B_USER="${CLIENT_B_USER:-$DEFAULT_B_USER}"
CLIENT_B_PASS="${CLIENT_B_PASS:-$DEFAULT_B_PASS}"
CLIENT_B_IP="${CLIENT_B_IP:-$DEFAULT_B_IP}"
CLIENT_B_DNS1="${CLIENT_B_DNS1:-$DEFAULT_B_DNS1}"
CLIENT_B_DNS2="${CLIENT_B_DNS2:-$DEFAULT_B_DNS2}"
CLIENT_B_RATE_DOWN="${CLIENT_B_RATE_DOWN:-$DEFAULT_B_RATE_DOWN}"
CLIENT_B_RATE_UP="${CLIENT_B_RATE_UP:-$DEFAULT_B_RATE_UP}"

add_client_user "$CLIENT_A_USER" "$CLIENT_A_PASS" "$CLIENT_A_IP" "$CLIENT_A_DNS1" "$CLIENT_A_DNS2" "$CLIENT_A_RATE_DOWN" "$CLIENT_A_RATE_UP"
add_client_user "$CLIENT_B_USER" "$CLIENT_B_PASS" "$CLIENT_B_IP" "$CLIENT_B_DNS1" "$CLIENT_B_DNS2" "$CLIENT_B_RATE_DOWN" "$CLIENT_B_RATE_UP"

echo "LDAP up on 120.0.32.69:389 (base dc=fai,dc=lab)"
