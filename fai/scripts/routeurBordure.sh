# routeur vers d'autre fai
# eth0 : 120.0.33.3/31
# eth1 : connection au reseau general 


# initialisation des interfaces 
# ip link set eth0 up
ip link set eth1 up

# initialisation des addresses IP
ip addr add 120.0.33.3/31 dev eth1

/usr/lib/frr/watchfrr.sh restart ospfd