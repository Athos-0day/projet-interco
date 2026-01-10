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
sysctl -w net.ipv4.conf.default.rp_filter=0

# Modules nécessaires pour le shaper en mode police
modprobe sch_ingress || true
modprobe cls_u32 || true
modprobe act_police || true
modprobe act_mirred || true
modprobe sch_htb || true
modprobe ifb || true
ip link add ifb0 type ifb 2>/dev/null || true
ip link set ifb0 up 2>/dev/null || true

# PPPoE access concentrator
mkdir -p /var/log/accel-ppp
mkdir -p /var/log
accel-pppd -c /etc/accel-ppp.conf &


/usr/lib/frr/watchfrr.sh restart zebra ospfd
sleep 1
vtysh -b /etc/frr/frr.conf
