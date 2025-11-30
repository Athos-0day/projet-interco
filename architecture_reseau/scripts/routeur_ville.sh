# cree un routeur ville
# relié a : 
# switch ville : 120.0.49.0/24
# reseau ville : 120.0.49+x.0/24 avec x le numéro de la ville (1 a 14) sénaio de base sur 2 villes


# création des interfaces
ip link set eth1 up
ip link set eth2 up

# recupération d'une adresse dans le réseau ville
dhlient eth1

# mise en place d'un server dhcp sur le reseau ville
ip addr add 120.0.49+$x.0/24 # surement pas juste
# a faire l'initialisation du serveur dhcp

