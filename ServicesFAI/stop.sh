#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <id services>"
    exit 1
fi

SERVICES_ID=$1

cd "$(dirname "$0")"

sudo ip link delete services${SERVICES_ID}_host 2>/dev/null || true
sudo ip netns delete services${SERVICES_ID}_switch 2>/dev/null || true

for c in services${SERVICES_ID}_dns services${SERVICES_ID}_web services${SERVICES_ID}_db; do
    docker kill "$c" >/dev/null 2>&1 || true
    docker rm "$c"   >/dev/null 2>&1 || true
done

sudo find /var/run/netns -xtype l -delete

echo "Réseau ServicesFAI ${SERVICES_ID} supprimé"
