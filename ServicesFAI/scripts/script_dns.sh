#!/bin/bash

set -e

ip link set lo up
ip link set eth0 up
ip addr add 120.0.48.66/28 dev eth0

# Relance propre du service
if pidof named > /dev/null; then
  killall named
fi
named -4 -c /etc/bind/named.conf -g > /var/log/named.log 2>&1 &

echo "DNS up on 120.0.48.66"
