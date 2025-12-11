#!/bin/bash

set -e

ip link set lo up
ip link set eth0 up
ip addr add 120.0.48.68/28 dev eth0
ip route add default via 120.0.48.65

mysqld_safe --bind-address=0.0.0.0 --skip-networking=0 > /var/log/mysqld.log 2>&1 &

# Attente du démarrage
until mariadb -uroot -e "SELECT 1" >/dev/null 2>&1; do
  sleep 1
done

mariadb -uroot <<'EOF'
CREATE DATABASE IF NOT EXISTS services;
CREATE USER IF NOT EXISTS 'service'@'%' IDENTIFIED BY 'servicepass';
GRANT ALL PRIVILEGES ON services.* TO 'service'@'%';
FLUSH PRIVILEGES;
EOF

echo "DB up on 120.0.48.68:3306 (user service/servicepass)"
