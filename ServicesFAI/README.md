# Services FAI

Ce dossier déploie quatre services du FAI dans des conteneurs Docker reliés par des namespaces réseau :
- `DNS` : Bind9 servant la zone `services.fai`.
- `WEB` : nginx.
- `DB`  : MariaDB ouverte sur le réseau interne (Je sais pas vraiment comment ca fonctionne ce truc).
- `LDAP` : OpenLDAP (base `dc=fai,dc=lab`).
- `RADIUS` : FreeRADIUS (auth LDAP + attributs de réponse).

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
  - Test ok : `docker exec -it fai_peParticulier radtest alice alicepass 120.0.32.70 0 peSecret123`
  - Test ko : `docker exec -it fai_peParticulier radtest alice wrongpass 120.0.32.70 0 peSecret123`
  - Debug FreeRADIUS : `docker exec -it servicesA_radius freeradius -X`
  - Dans le test ok, vérifier `Access-Accept` et les attributs `Framed-IP-Address`, `MS-Primary-DNS-Server`, `MS-Secondary-DNS-Server`.

## PPPoE + IP/DNS via RADIUS (IPCP)
- Redémarrer RADIUS (si besoin) :
  - `docker exec -it servicesA_radius pkill freeradius`
  - `docker exec -it servicesA_radius freeradius`
- Redémarrer accel-ppp (PE Particulier) :
  - `docker exec -it fai_peParticulier pkill accel-pppd`
  - `docker exec -it fai_peParticulier accel-pppd -c /etc/accel-ppp.conf &`
- Sur une box abonnée (ex: `particulierA_box`) :
  - `docker exec -it particulierA_box bash`
  - `pkill dhclient || true`
  - `ip link set eth0 up`
  - `cat > /etc/ppp/peers/fai <<'EOF'
user "alice"
plugin rp-pppoe.so
eth0
noauth
defaultroute
persist
mtu 1492
mru 1492
usepeerdns
EOF`
  - `echo 'alice * "alicepass"' > /etc/ppp/pap-secrets`
  - `pppd call fai nodetach debug`
- Vérifier l’IP WAN + DNS :
  - `ip addr show ppp0`
  - `cat /etc/ppp/resolv.conf`
- Vérifier la connectivité (NAT toujours actif côté box) :
  - `ping -c 2 120.0.35.1`
  - `ping -c 2 120.0.32.66`
  - `curl 120.0.32.67`
- Logs utiles :
  - FreeRADIUS : `docker exec -it servicesA_radius freeradius -X`
  - PPP/accel-ppp : `docker exec -it fai_peParticulier tail -n 50 /var/log/accel-ppp/accel-ppp.log`

## Accounting RADIUS (Start/Stop/Interim)
- Démarrer FreeRADIUS en debug :
  - `docker exec -it servicesA_radius pkill freeradius`
  - `docker exec -it servicesA_radius freeradius -X`
- (Re)lancer accel-ppp (PE Particulier) :
  - `docker exec -it fai_peParticulier pkill accel-pppd`
  - `docker exec -it fai_peParticulier accel-pppd -c /etc/accel-ppp.conf &`
- Établir puis couper une session PPPoE (box) :
  - `docker exec -it particulierA_box pppd call fai nodetach debug`
  - Arrêt : `pkill pppd`
- Vérifier les logs d’accounting (detail) :
  - `docker exec -it servicesA_radius tail -n 50 /var/log/freeradius/radacct/120.0.33.41/detail`
- Exemple d’entrées (attendu) :
  - `Acct-Status-Type = Start` + `User-Name = "alice"` + `Framed-IP-Address = 120.0.35.100`
  - `Acct-Status-Type = Stop` + `Acct-Session-Time = <secondes>`

## fichiers de config:
- Adapter la zone DNS dans `configs/dns/`.
- Modifier la page web dans `configs/web/index.html`.
- Ajuster la config MariaDB dans `configs/db/60-bind.cnf` ou l'initialisation dans `scripts/script_db.sh`.
- LDAP initialisation dans `scripts/script_ldap.sh`.
- RADIUS clients/utilisateurs dans `configs/radius/`.
