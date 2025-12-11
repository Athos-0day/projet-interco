# routeurBordeaux : 120.0.49.21/31
# routeurLyon : 120.0.49.31/31
# peParticulier : 120.0.49.40/31

ip link set eth0 up
ip link set eth1 up
ip link set eth2 up

# ajout des adresses IP des interfaces
ip addr add 120.0.49.21/31 dev eth0
ip addr add 120.0.49.31/31 dev eth1
ip addr add 120.0.49.40/31 dev eth2