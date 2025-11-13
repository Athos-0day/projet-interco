# Script pour la gestion des interfaces de la box

# Creation d'un bridge entre eth1 et eth2
ip link add name br0 type bridge
ip link set eth1 master br0
ip link set eth2 master br0
ip link set eth1 up
ip link set eth2 up
ip link set br0 up

# interface client
ip addr add 192.168.1.1/24 dev br0

# On démare le service DHCP
/etc/init.d/isc-dhcp-server start 
