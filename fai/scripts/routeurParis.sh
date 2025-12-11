# routeurBordure : 120.0.49.2/31
# peEntreprise : 120.0.49.4/31
# peService : 120.0.49.6/31
# routeurLyon : 120.0.49.8/31
# routeurBordeaux : 120.0.49.10/31

ip link set eth0 up
ip link set eth1 up
ip link set eth2 up
ip link set eth3 up
ip link set eth4 up

# ajout des adresses IP des interfaces
ip addr add 120.0.49.2/31 dev eth0
ip addr add 120.0.49.4/31 dev eth1
ip addr add 120.0.49.6/31 dev eth2
ip addr add 120.0.49.8/31 dev eth3
ip addr add 120.0.49.10/31 dev eth4

/usr/lib/frr/watchfrr.sh restart ospfd