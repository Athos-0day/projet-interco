# creation du routeur dns
# interfaces :
# eth0 : routeurParis 120.0.49.4/31
# eth1 : ReseauEntreprise 120.0.50.1/24


# initialisation des interfaces :
ip link set eth0 up
#ip link set eth1 up

# initialisation des addresses ip
ip addr add 120.0.49.4/31 dev eth0
#ip addr add 120.0.48.65/28 dev eth1
