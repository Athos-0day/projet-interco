#!/bin/bash

set -e

ip link set lo up
ip link set eth0 up
ip addr add 120.0.32.67/28 dev eth0
ip route add default via 120.0.32.65

nginx -s stop 2>/dev/null || true
nginx

echo "Web up on 120.0.32.67:80"
