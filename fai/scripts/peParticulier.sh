# Script pour la gestion des interfaces du routeur

ip link set eth1 up
ip addr add 120.0.51.1/24 dev eth1

# On démare le service DHCP
/etc/init.d/isc-dhcp-server start > /dev/null &
