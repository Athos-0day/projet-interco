# Script pour la gestion des interfaces de la box

# Creation d'un bridge entre eth1 et eth2
ip link add name br0 type bridge
ip link set eth1 master br0
ip link set eth2 master br0
ip link set eth1 up
ip link set eth2 up
ip link set br0 up

# adresse ip locale
ip addr add 192.168.1.1/24 dev br0

# NAT
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j MASQUERADE

# On démarre le service DHCP
/etc/init.d/isc-dhcp-server start > /dev/null &

# DNS forwarder for LAN clients
cat > /etc/dnsmasq.d/box.conf <<'EOF'
interface=br0
bind-interfaces

# Utilise les DNS fournis par PPP
resolv-file=/etc/ppp/resolv.conf

domain-needed
bogus-priv
EOF
dnsmasq -C /etc/dnsmasq.d/box.conf
if ! grep -q '^options timeout:1 attempts:1' /etc/resolv.conf 2>/dev/null; then
    printf "\noptions timeout:1 attempts:1\n" >> /etc/resolv.conf
fi

# On démarre PPPoE pour recevoir l'adresse IP publique
if [ -z "$PPP_USER" ] || [ -z "$PPP_PASS" ]; then
    echo "PPP_USER/PPP_PASS not set; cannot start PPPoE"
    exit 1
fi

mkdir -p /etc/ppp/peers
mkdir -p /etc/ppp
cat > /etc/ppp/peers/fai <<EOF
user "${PPP_USER}"
plugin rp-pppoe.so
eth0
noauth
defaultroute
persist
mtu 1492
mru 1492
usepeerdns
holdoff 5
maxfail 0
EOF

echo "${PPP_USER} * \"${PPP_PASS}\"" > /etc/ppp/pap-secrets

ip link set eth0 up

cat > /etc/ppp/ip-up <<'EOF'
#!/bin/sh
if [ -f /etc/ppp/resolv.conf ]; then
    cp /etc/ppp/resolv.conf /etc/resolv.conf
fi

if pidof dnsmasq >/dev/null 2>&1; then
    kill -HUP "$(pidof dnsmasq)" 2>/dev/null || true
fi

if ! grep -q '^options timeout:1 attempts:1' /etc/resolv.conf 2>/dev/null; then
    printf "\noptions timeout:1 attempts:1\n" >> /etc/resolv.conf
fi
EOF
chmod +x /etc/ppp/ip-up

pppd call fai
