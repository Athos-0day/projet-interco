# cree un routeur ville
# relié a : 
# switch ville : 120.0.49.0/24
# reseau ville : 120.0.49+x.0/24 avec x le numéro de la ville (1 a 14) sénaio de base sur 2 villes

if [ "$#" -ne 1 ] ; then #&& [ "$#" -ne 3 ]
    echo "Usage: $0 <id fai> "
    exit 1
fi


# création des interfaces
ip link set eth1 up
ip link set eth2 up

# recupération d'une adresse dans le réseau ville
dhlient eth1

IP_PLAGE= 49 + $1
# mise en place d'un server dhcp sur le reseau ville
ip addr add 120.0.${IP_PLAGE}.1/24 dev eth2 # surement pas juste
# a faire l'initialisation du serveur dhcp


# creation du fichier de config dhcp.conf
echo "default-lease-time 600;" > /etc/dhcp/dhcp.conf
echo "max-lease-time 7200;" >> /etc/dhcp/dhcp.conf

echo "authoritative;" >> /etc/dhcp/dhcp.conf

echo "subnet 120.0.${IP_PLAGE}.0 netmask 255.255.255.0 {" >> /etc/dhcp/dhcp.conf
echo "  range 120.0.${IP_PLAGE}.10 120.0.${IP_PLAGE}.100;" >> /etc/dhcp/dhcp.conf
echo "  option subnet-mask 255.255.255.0;" >> /etc/dhcp/dhcp.conf
echo "  option broadcast-address 120.0.${IP_PLAGE}.255;" >> /etc/dhcp/dhcp.conf
echo "  option routers 120.0.${IP_PLAGE}.1;" >> /etc/dhcp/dhcp.conf
echo "  option domain-name-servers 11.0.0.2;" >> /etc/dhcp/dhcp.conf
echo "}"

# On démarre le service DHCP
/etc/init.d/isc-dhcp-server start > /dev/null &