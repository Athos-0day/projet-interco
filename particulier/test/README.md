# Tests

Ce dossier contient les fichiers permettant la création d'une infrastucture minimale afin de tester le DHCP
et le NAT des réseaux de particuliers.

Le script ./start.sh crée un réseau particulierA et le connecte à un routeur fai_particulierA sur eth1.
Le routeur FAI utilise DHCP pour configurer l'ip publique de la box.

# Vérifications

Pour vérifier le bon fonctionnement du NAT :
- Démarrer l'infrastructure de test : `test/start.sh`
- Ouvrir Wireshark sur le routeur FAI : `sudo ip netns exec fai_particulierA wireshark 2> /dev/null &`
- Ping le routeur FAI depuis particulierA_t1 : `docker exec -it particulierA_t1 bash -c "ping 10.0.10.1"`
- Vérifier que particulierA_t1 reçoit des réponses et que les pings reçus par le routeur FAI ont l'adresse IP publique de la box.