# creation du routeur dns
# interfaces :
# eth0 : routeur_central 120.0.48.50/28
# eth1 : serveur_DNS 120.48.65/28


# initialisation des interfaces :
ip link set eth0 up
ip link set eth1 up

# initialisation des addresses ip
ip addr add 120.0.48.50/28 dev eth0
ip addr add 120.0.48.65/28 dev eth1
