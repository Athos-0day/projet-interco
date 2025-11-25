# Réseau de l'entreprise 

Le réseau de l'entreprise est constitué de :

- Un sous-réseau avec les services de l'entreprise : **VoIP**, **DNS**, **serveur WEB**
- Un sous-réseau (réplicable) avec des **machines utilisateurs** (ex : Service RH, Service Financier)
- Un **serveur VPN** situé sur le routeur public, qui relie Internet au réseau interne
- Trois routeurs portant les noms :
  - **routeur public**
  - **routeur services**
  - **routeur machine**

---

## Schéma de l'infrastructure

![Architecture du réseau de l'entreprise](docs/ReseauEntreprise.jpg)

---

## Sous-réseau Services (IP fixes)

Le sous-réseau *Services* contient toutes les machines essentielles :  

| Service | IP | Description |
|--------|---------|------------|
| DNS (Bind9) | **192.168.49.18** | Résolution interne/externe |
| Serveur Web (NGINX) | **192.168.49.20** | Héberge les sites interne et externe |
| Serveur VoIP | **192.168.49.19** | Service téléphonie interne |

Toutes les machines du réseau Services utilisent **des adresses IP fixes**, configurées manuellement dans les conteneurs via leurs scripts de démarrage.

---

## Sous-réseau Machines (DHCP)

Le sous-réseau Machines correspond aux ordinateurs des employés.

- Ils sont **en DHCP** et reçoivent automatiquement :
  - Leur **adresse IP**
  - Le **DNS interne** : 192.168.49.18  
  - La **passerelle** : routeur machine

Ce réseau peut être **répliqué** (plusieurs services RH, Finances, etc. avec le même schéma).

---

## Serveur Web

Le serveur web tourne sur **NGINX**, adresse IP : **192.168.49.20**

Deux sites sont proposés :

### Site interne
- **Nom de domaine** : `intra.site.lan`
- **Chemin serveur** : `/intranet`
- **Accessibilité** : uniquement depuis l’intérieur de l’entreprise  
  (filtré par NGINX ou firewall)

### Site externe
- **Nom de domaine** : `www.site.lan`
- **Chemin serveur** : `/public`
- **Accessibilité** : accessible partout (via IP publique du routeur public)

---

## Serveur DNS

Le serveur DNS utilise **Bind9**, IP : **192.168.49.18**

Il fournit deux types de résolutions :

### Résolution interne
Pour les machines du LAN :

| Nom de domaine | Adresse renvoyée |
|----------------|------------------|
| `intra.site.lan` | **192.168.49.20** |
| `www.site.lan` | **192.168.49.20** |

### Résolution externe
Pour le monde extérieur :

| Nom de domaine | Adresse renvoyée |
|----------------|------------------|
| `www.site.lan` | **120.0.50.2** (IP publique du routeur public) |

Cela permet :

- Aux utilisateurs internes d’accéder directement au serveur web local  
- Aux utilisateurs extérieurs de passer par le routeur public

---

## Résumé global

- Le **réseau Services** fonctionne en **IP fixes**
- Le **réseau Machines** fonctionne **en DHCP**
- Le **DNS interne** résout différemment selon l'origine de la requête
- Le **serveur web** sépare les contenus internes et externes  
- L’architecture est segmentée via trois routeurs coordonnés

---
