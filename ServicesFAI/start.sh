#!/bin/bash

# Démarre le réseau ServicesFAI :
# - DNS Bind9
# - Site web (nginx)
# - Base de données (MariaDB)

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <id services>"
    exit 1
fi

SERVICES_ID=$1

cd "$(dirname "$0")"

# Images
docker build -q -t services_fai_dns ./images/dns
docker build -q -t services_fai_web ./images/web
docker build -q -t services_fai_db ./images/db

# Containers
docker create -it --name services${SERVICES_ID}_dns --hostname services${SERVICES_ID}_dns --network none --privileged services_fai_dns
docker create -it --name services${SERVICES_ID}_web --hostname services${SERVICES_ID}_web --network none --privileged services_fai_web
docker create -it --name services${SERVICES_ID}_db  --hostname services${SERVICES_ID}_db  --network none --privileged services_fai_db

docker start services${SERVICES_ID}_dns
docker start services${SERVICES_ID}_web
docker start services${SERVICES_ID}_db

# Expose les netns Docker
addNetnsList() {
    pid=$(docker inspect -f '{{.State.Pid}}' "$1")
    sudo mkdir -p /var/run/netns/
    sudo ln -sfT /proc/$pid/ns/net /var/run/netns/$1
}

addNetnsList services${SERVICES_ID}_dns
addNetnsList services${SERVICES_ID}_web
addNetnsList services${SERVICES_ID}_db

# Switch
sudo ip netns add services${SERVICES_ID}_switch
sudo ip netns exec services${SERVICES_ID}_switch ip link set lo up
sudo ip netns exec services${SERVICES_ID}_switch ip link add br0 type bridge
sudo ip netns exec services${SERVICES_ID}_switch ip link set br0 up

# Accès depuis l'host pour les tests (120.0.48.65)
#sudo ip link add services${SERVICES_ID}_host type veth peer name host0 netns services${SERVICES_ID}_switch
#sudo ip addr add 120.0.48.65/28 dev services${SERVICES_ID}_host
#sudo ip link set services${SERVICES_ID}_host up
#sudo ip netns exec services${SERVICES_ID}_switch ip link set host0 master br0
#sudo ip netns exec services${SERVICES_ID}_switch ip link set host0 up

# Version pour connecter un conteneur routeur
sudo ip netns exec services${SERVICES_ID}_switch ip link add router0 type veth peer name router1
sudo ip netns exec services${SERVICES_ID}_switch ip link set router0 master br0
sudo ip netns exec services${SERVICES_ID}_switch ip link set router0 up

# Lien container switch
addLinkToSwitch() {
    local container="$1"
    local if_container="$2"
    local if_switch="$3"

    sudo ip netns exec "$container" ip link add "$if_container" type veth peer name "$if_switch" netns services${SERVICES_ID}_switch
    sudo ip netns exec services${SERVICES_ID}_switch ip link set "$if_switch" master br0
    sudo ip netns exec services${SERVICES_ID}_switch ip link set "$if_switch" up
}

addLinkToSwitch services${SERVICES_ID}_dns eth0 dns0
addLinkToSwitch services${SERVICES_ID}_web eth0 web0
addLinkToSwitch services${SERVICES_ID}_db  eth0 db0

# Copie des configs
docker cp configs/dns/named.conf.options services${SERVICES_ID}_dns:/etc/bind/named.conf.options
docker cp configs/dns/named.conf.local   services${SERVICES_ID}_dns:/etc/bind/named.conf.local
docker cp configs/dns/db.services.fai    services${SERVICES_ID}_dns:/etc/bind/db.services.fai

docker cp configs/web/index.html         services${SERVICES_ID}_web:/var/www/html/index.html
docker cp configs/web/site.conf          services${SERVICES_ID}_web:/etc/nginx/sites-available/default

docker cp configs/db/60-bind.cnf         services${SERVICES_ID}_db:/etc/mysql/mariadb.conf.d/60-bind.cnf

# Démarrage des services
cat scripts/script_dns.sh | docker exec -i services${SERVICES_ID}_dns bash &
cat scripts/script_web.sh | docker exec -i services${SERVICES_ID}_web bash &
cat scripts/script_db.sh  | docker exec -i services${SERVICES_ID}_db  bash &

echo "Réseau ServicesFAI ${SERVICES_ID} démarré (120.0.48.64/28)"
