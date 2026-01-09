# Script pour la gestion des interfaces du routeur

ip link set eth0 up
ip link set eth1 up

ip addr add 120.0.33.41/31 dev eth0

# Résolution DNS interne et hostname local (évite les timeouts)
printf "nameserver 120.0.32.66\noptions timeout:1 attempts:1\n" > /etc/resolv.conf
printf "120.0.33.41\t%s\n" "$(hostname)" >> /etc/hosts

# Activer le routage pour relayer le trafic PPP vers le coeur
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.rp_filter=0

# PPPoE access concentrator
mkdir -p /var/log/accel-ppp
mkdir -p /var/log
accel-pppd -c /etc/accel-ppp.conf &


/usr/lib/frr/watchfrr.sh restart ospfd
