# routeur de l'intranet
# eth0 : 120.0.48.34/28
# eth1 : connection au reseau general 


# initialisation des interfaces 
ip link set eth0 up
ip link set eth1 up

# initialisation des addresses IP
ip addr add 120.0.48.34/28 dev eth0
dhclient eth1
