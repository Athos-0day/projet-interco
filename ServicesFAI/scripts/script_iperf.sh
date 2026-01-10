#!/bin/bash

set -e

IPERF_IP="120.0.32.71/28"

ip link set lo up
ip link set eth0 up
ip addr add "$IPERF_IP" dev eth0
ip route add default via 120.0.32.65

printf "nameserver 120.0.32.66\noptions timeout:1 attempts:1\n" > /etc/resolv.conf

if pidof iperf3 > /dev/null; then
  killall iperf3
fi

iperf3 -s -D --logfile /var/log/iperf3.log

echo "iperf3 server up on 120.0.32.71:5201"
