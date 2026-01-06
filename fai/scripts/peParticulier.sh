# Script pour la gestion des interfaces du routeur

ip link set eth0 up
ip link set eth1 up

ip addr add 120.0.33.41/31 dev eth0
ip addr add 120.0.35.1/24 dev eth1

# Résolution DNS interne et hostname local (évite les timeouts)
printf "nameserver 120.0.32.66\noptions timeout:1 attempts:1\n" > /etc/resolv.conf
printf "120.0.33.41\t%s\n" "$(hostname)" >> /etc/hosts

# On démare le service DHCP
touch /var/lib/dhcp/dhcpd.leases
dhcpd -cf /etc/dhcp/dhcpd.conf eth1 &


/usr/lib/frr/watchfrr.sh restart ospfd
