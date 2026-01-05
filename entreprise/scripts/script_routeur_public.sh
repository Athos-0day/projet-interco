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
ip addr add 120.0.34.2/24 dev eth0
ip link set eth0 up

### --------------------------------------
### 2 — Activation du routage
### --------------------------------------
echo 1 > /proc/sys/net/ipv4/ip_forward

# Lancement OSPF

/lib/frr/frrinit.sh  start

### --------------------------------------
### 3 — Routage statique
### --------------------------------------
ip route add 192.168.49.32/28 via 192.168.49.3   # routeur machines
ip route add 192.168.49.16/28 via 192.168.49.2   # routeur services


### ======================================
### 4 — FIREWALL : iptables
### ======================================

echo "[INFO] Configuration du firewall"

# # Remise à zéro
# iptables -F
# iptables -t nat -F
# iptables -X

# # Stratégies par défaut
# iptables -P INPUT DROP
# iptables -P FORWARD DROP
# iptables -P OUTPUT ACCEPT


# Autoriser le LAN interne
# ---------------------------
# iptables -A INPUT -s 192.168.49.0/24 -j ACCEPT
#
#
# # ---------------------------
# # Autoriser loopback
# # ---------------------------
# iptables -A INPUT -i lo -j ACCEPT
#
#
# # ---------------------------
# Autoriser trafic entrant EXTERNE :
# uniquement Web (80) et DNS (53)
# ---------------------------

PUBLIC_NET="120.0.32.0/20"
DNS_IP="192.168.49.18"
WEB_IP="192.168.49.20"
LAN_NET="192.168.49.0/28"
### --------------------------------------
### 1 — Nettoyage et Politiques par défaut
### --------------------------------------
iptables -F
iptables -t nat -F
iptables -X

# On bloque tout par défaut (Sécurité)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

### --------------------------------------
### 2 — Autorisations pour le Routeur lui-même (INPUT)
### --------------------------------------
iptables -A INPUT -i lo -j ACCEPT                             # Loopback
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT # Réponses aux requêtes du routeur
iptables -A INPUT -p icmp -j ACCEPT                           # Autoriser le Ping sur le routeur
iptables -A INPUT -p ospf -j ACCEPT                           # Autoriser les messages OSPF
iptables -A INPUT -p udp --dport 1194 -j ACCEPT               # Autoriser les connexions vpn

### --------------------------------------
### 3 — Port Forwarding & Flux Web (Externe -> Interne)
### --------------------------------------
# 1. Redirection NAT du port 80
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination $WEB_IP:80

# 2. Autoriser le trafic forwardé pour le Web (uniquement port 80)
iptables -A FORWARD -p tcp -d $WEB_IP --dport 80 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

### --------------------------------------
### 4 — Accès Sortant (Interne -> Système Autonome/Internet)
### --------------------------------------
# Autoriser tout le trafic qui vient de l'intérieur vers l'extérieur
iptables -A FORWARD -s $LAN_NET -i br0 -j ACCEPT

# Autoriser le retour du trafic déjà établi (indispensable pour que le LAN reçoive les réponses)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Autoriser le traffic provenant du tunnel vpn
iptables -A FORWARD -s 10.99.0.0/24 -j ACCEPT

# NAT : Masquerade pour la sortie sur eth0
iptables -t nat -A POSTROUTING -s $LAN_NET -o eth0 -j MASQUERADE

echo "[OK] Firewall actif :"
echo "     - Externe -> Interne : Port 80 uniquement"
echo "     - Interne -> Externe : Autorisé (Accès SA/Internet)"echo "[INFO] Routeur public configuré avec firewall."

### --------------------------------------
### 5 — VPN 
### --------------------------------------

# Initialisation du PKI du vpn
export EASYRSA_BATCH=1
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa/
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa build-server-full server nopass

# generation des paramèters DH 
#./easyrsa gen-dh # Trop long dans un docker sans entropie
cat > pki/dh.pem <<'EOF'
-----BEGIN DH PARAMETERS-----
MIIBDAKCAQEAqiWdTajiVhusVuOyejpfIc03eqOACoE76bWm95ljOp/q1d6eJL9v
iaKtH+iQT40hkMyYOHNlmkm1LgaBOwYhyO4roXkudNHM23sSRzSll+aqnp19qhcV
lS4nuJHbXq3iOPlnJutl8iFrrksJYteH+tmzvmuW4NVA6qDi+cVrYtSpuSaujk4U
50c+bDictXAsSmCGfVK5sqzm6r58SlZvAIQ92Yo/W7RUZliW1Dvmexln4lJDhDRm
ZcDjDMCGl0PMH+HjJxHlhbNU9lUZHYWtmdwHD8GbtAQbUlmKgF+NzqlbpPJWVVff
hB4ufBQtLeYjq+M1oX0mEPa+YyS+In6NLwIBAgICAOE=
-----END DH PARAMETERS-----
EOF

# Generation de la clef d'authentification TLS 
openvpn --genkey secret /etc/openvpn/server/ta.key

## Parametrage d'autentification -- fichier config copier lors de la creation du docker


EASYRSA_DIR="/etc/openvpn/easy-rsa"
PKI_DIR="$EASYRSA_DIR/pki"
OUTPUT_DIR="/home/client_ovpn"

mkdir -p "$OUTPUT_DIR"
CLIENT_ID="test"
echo "Création du certificat pour $CLIENT_ID"

# creation de la clée 
cd $EASYRSA_DIR
./easyrsa --batch build-client-full $CLIENT_ID nopass


# generation du fichier .ovpn a donner au client 
cp /etc/openvpn/client.conf $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "<ca>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
cat $PKI_DIR/ca.crt >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "</ca>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "<cert>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' <$PKI_DIR/issued/$CLIENT_ID.crt >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "</cert>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "<key>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
cat $PKI_DIR/private/$CLIENT_ID.key >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "</key>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "<tls-auth>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn
sed -n '/BEGIN OpenVPN Static key V1/,/END OpenVPN Static key V1/p' < /etc/openvpn/server/ta.key >> $OUTPUT_DIR/$CLIENT_ID.ovpn
echo "</tls-auth>" >> $OUTPUT_DIR/$CLIENT_ID.ovpn

# demarage du vpn 
while ! openvpn --config /etc/openvpn/server.conf; do
    echo "OpenVPN failed — retrying in 5 seconds..."
    sleep 5
done &

