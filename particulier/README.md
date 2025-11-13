# Réseau de particulier

Un réseau de particulier est composé de :
- Une box jouant le rôle de **serveur DHCP** permettant d'attribuer des adresses IP dynamiques et de point d'accès vers le réseau  de l'opérateur.
- De deux machines connectées à la box.

Les réseaux de particuliers possède un identifiant (A,B,C,...) défini par l'utilisateur qui permet de les différenciers.

## Procédure de déploiement

Dépendances :
 - Docker

Pour démarrer un réseau de particulier A :
```bash
chmod u+x ./start.sh
./start.sh A
```

Pour arrêter un réseau de particulier A :
```bash
chmod u+x ./stop.sh
./stop.sh A
```

## Accès aux machines

Les machines d'un réseau de particulier A ont les noms suivants :
- `particulierA_box` pour la box
- `particulierA_t1`
- `particulierA_t2`

Pour ouvrir un terminal sur une machine d'un réseau de particulier A :
```bash
docker exec -it nom_machine bash
```

Pour ouvrir wireshark en tant qu'une machine du réseau (nécessite Wireshark installé sur l'hôte) :
```bash
sudo ip netns exec nom_machine wireshark
```

## Configuration

Les images utilisées sont définies dans le dossier images, les scripts de démarrage utilisés sont définis dans le dossier scripts et les fichiers de configurations dans le dossier configs.
