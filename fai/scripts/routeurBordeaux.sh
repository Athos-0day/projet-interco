# routeurParis : 120.0.33.11/31
# routeurToulouse : 120.0.33.20/31

ip link set eth0 up
ip link set eth1 up

# ajout des adresses IP des interfaces
ip addr add 120.0.33.11/31 dev eth0
ip addr add 120.0.33.20/31 dev eth1

/usr/lib/frr/watchfrr.sh restart ospfd