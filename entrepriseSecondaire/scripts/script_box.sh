# Script pour la gestion des interfaces de la box

# Creation d'un bridge entre eth1 et eth2
ip link add name br0 type bridge
ip link set eth1 master br0
ip link set eth2 master br0
ip link set eth1 up
ip link set eth2 up
ip link set br0 up

# adresse ip locale
ip addr add 192.168.2.1/24 dev br0

# NAT
iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -j MASQUERADE

# On démarre le service DHCP
/etc/init.d/isc-dhcp-server start > /dev/null &

# On démarre le client DHCP pour recevoir l'adresse IP publique
dhclient eth0 
