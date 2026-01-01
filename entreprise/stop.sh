#!/bin/bash

echo "[INFO] Arrêt des conteneurs Docker du projet..."

# Liste des conteneurs à arrêter
CONTAINERS=(
    "entreprise_dns"
    "entreprise_web"
    "entreprise_routeur_services"
    "entreprise_routeur_public"
    "entreprise_routeur_bureau_*"
    "entreprise_client1_*"
    "entreprise_client2_*"
    "entreprise_voip"
    "entreprise_ldap"
)

# Arrêt + suppression
for c in "${CONTAINERS[@]}"; do
    for instance in $(docker ps -a --format '{{.Names}}' | grep "$c"); do
        echo "[INFO] Arrêt de $instance..."
        docker kill "$instance" >/dev/null 2>&1
        docker rm "$instance" >/dev/null 2>&1
        echo "[INFO] $instance arrêté et supprimé."

        # Nettoyage du namespace réseau
        if [ -e "/var/run/netns/$instance" ]; then
            sudo rm -f "/var/run/netns/$instance"
            echo "[INFO] Namespace $instance supprimé."
        fi
    done
done

echo "[INFO] Tous les conteneurs du projet ont été arrêtés."
