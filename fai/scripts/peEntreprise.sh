# creation du routeur dns
# interfaces :
# eth0 : routeurParis 120.0.33.4/31
# eth1 : ReseauEntreprise 120.0.34.1/24


# initialisation des interfaces :
ip link set eth0 up
ip link set eth1 up

# initialisation des addresses ip
ip addr add 120.0.33.5/31 dev eth0
ip addr add 120.0.34.1/24 dev eth1

# Autoriser le routage L3 et eviter les drops en cas de chemins asymetriques.
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0


/usr/lib/frr/watchfrr.sh restart zebra ospfd
sleep 1
vtysh -b /etc/frr/frr.conf
