# Services FAI

Ce dossier déploie quatre services du FAI dans des conteneurs Docker reliés par des namespaces réseau :
- `DNS` : Bind9 servant la zone `services.fai`.
- `WEB` : nginx.
- `DB`  : MariaDB ouverte sur le réseau interne (Je sais pas vraiment comment ca fonctionne ce truc).
- `LDAP` : OpenLDAP (base `dc=fai,dc=lab`).
- `RADIUS` : FreeRADIUS (auth locale pour tests).

Le LAN interne utilise `120.0.32.64/28`
L'hôte est relié au switch via l'interface `services<ID>_host` en `120.0.32.65` pour tests. On peut mettre un routeur à la place

Les adresses :
- DNS : `120.0.32.66` (`dns.services.fai`)  
- Web : `http://120.0.32.67` (`web.services.fai`)  
- DB  : `120.0.32.68:3306` (`db.services.fai`, user `service` / `servicepass`)
- LDAP: `120.0.32.69:389` (`ldap.services.fai`)
- RADIUS: `120.0.32.70:1812/1813` (`radius.services.fai`)

## Vérifications:
- Résolution DNS : `dig @120.0.32.66 web.services.fai`
- Site web : `curl 120.0.32.67`
- Base de données : `mariadb -h 120.0.32.68 -uservice -pservicepass -e "SHOW DATABASES;"`(tkt)
- LDAP base DN : `docker exec -it servicesA_web ldapsearch -x -H ldap://120.0.32.69 -D "cn=admin,dc=fai,dc=lab" -w adminpass -b "dc=fai,dc=lab" -s base`
- LDAP OUs : `docker exec -it servicesA_web ldapsearch -x -H ldap://120.0.32.69 -D "cn=admin,dc=fai,dc=lab" -w adminpass -b "dc=fai,dc=lab" "(objectClass=organizationalUnit)"`
- LDAP compte RADIUS : `docker exec -it servicesA_web ldapsearch -x -H ldap://120.0.32.69 -D "cn=admin,dc=fai,dc=lab" -w adminpass -b "cn=radius,ou=svc,dc=fai,dc=lab"`
- LDAP clients : `docker exec -it servicesA_web ldapsearch -x -H ldap://120.0.32.69 -D "cn=admin,dc=fai,dc=lab" -w adminpass -b "ou=clients,dc=fai,dc=lab" "(|(uid=alice)(uid=bob))"`
- RADIUS (depuis le PE Particulier `fai_peParticulier`) :
  - Test ok : `docker exec -it fai_peParticulier radtest testuser testpass 120.0.32.70 0 peSecret123`
  - Test ko : `docker exec -it fai_peParticulier radtest testuser wrongpass 120.0.32.70 0 peSecret123`
  - Debug FreeRADIUS : `docker exec -it servicesA_radius freeradius -X`
  - Dans le test ok, vérifier `Access-Accept` et les attributs `Framed-IP-Address`, `MS-Primary-DNS-Server`, `MS-Secondary-DNS-Server`.

## fichiers de config:
- Adapter la zone DNS dans `configs/dns/`.
- Modifier la page web dans `configs/web/index.html`.
- Ajuster la config MariaDB dans `configs/db/60-bind.cnf` ou l'initialisation dans `scripts/script_db.sh`.
- LDAP initialisation dans `scripts/script_ldap.sh`.
- RADIUS clients/utilisateurs dans `configs/radius/`.
