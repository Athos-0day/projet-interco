# routeurBordure : 120.0.33.2/31
# peEntreprise : 120.0.33.4/31
# peService : 120.0.33.6/31
# routeurLyon : 120.0.33.8/31
# routeurBordeaux : 120.0.33.10/31

ip link set eth0 up
ip link set eth1 up
ip link set eth2 up
ip link set eth3 up
ip link set eth4 up

# ajout des adresses IP des interfaces
ip addr add 120.0.33.2/31 dev eth0
ip addr add 120.0.33.4/31 dev eth1
ip addr add 120.0.33.6/31 dev eth2
ip addr add 120.0.33.8/31 dev eth3
ip addr add 120.0.33.10/31 dev eth4

# Autoriser le routage L3 et eviter les drops en cas de chemins asymetriques.
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0

/usr/lib/frr/watchfrr.sh restart zebra ospfd
sleep 1
vtysh -b /etc/frr/frr.conf
