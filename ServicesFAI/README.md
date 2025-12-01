# Services FAI

Ce dossier déploie trois services du FAI dans des conteneurs Docker reliés par des namespaces réseau :
- `DNS` : Bind9 servant la zone `services.fai`.
- `WEB` : nginx.
- `DB`  : MariaDB ouverte sur le réseau interne (Je sais pas vraiment comment ca fonctionne ce truc).

Le LAN interne utilise `120.0.48.64/28`
L'hôte est relié au switch via l'interface `services<ID>_host` en `120.0.48.65` pour tests. On peut mettre un routeur à la place

Les adresses :
- DNS : `120.0.48.66` (`dns.services.fai`)  
- Web : `http://120.0.48.67` (`web.services.fai`)  
- DB  : `120.0.48.68:3306` (`db.services.fai`, user `service` / `servicepass`)

## Vérifications:
- Résolution DNS : `dig @120.0.48.66 web.services.fai`
- Site web : `curl 120.0.48.67`
- Base de données : `mariadb -h 120.0.48.68 -uservice -pservicepass -e "SHOW DATABASES;"`(tkt)

## fichiers de config:
- Adapter la zone DNS dans `configs/dns/`.
- Modifier la page web dans `configs/web/index.html`.
- Ajuster la config MariaDB dans `configs/db/60-bind.cnf` ou l'initialisation dans `scripts/script_db.sh`.
