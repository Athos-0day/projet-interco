# scripte pour le routeur central
# se raccorde au routeurs suivants :
# routeur_intranet : 120.0.48.32/28
# routeurs_villes : 120.0.49.0/24 (2)
# routeur_dns : 120.0.48.48/28

# creation des 3 interfaces :
ip link set eth1 up
ip link set eth2 up
ip link set eth3 up

# ajout des adresses IP des interfaces
ip a a 120.0.48.33/28 dev eth1
ip addr add 120.0.49.1/24 dev eth2
ip addr add 120.0.48.49/28 dev eth3

# mettre en place l'adressage dynamique sur les 3 interfaces
