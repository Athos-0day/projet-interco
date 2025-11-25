# Réseau de l'entreprise 

Le réseau de l'entreprise est constitué de :
- Un sous-réseau avec les services de l'entreprise, les services proposés sont **VoIP**, **DNS** et **serveur WEB**
- Un sous-réseau (réplicable) avec des machines utilisateurs de l'entreprise représentant par exemple un service (RH ou Financier)
- Le **serveur VPN** se trouve sur le routeur qui lie le réseau public et celui de l'entreprise

Les routeurs ont les noms respectifs (routeur public, routeur services et routeur machine) et des switchs.

## Serveur Web

Le serveur web est un serveur NGINX, avec l'IP: **192.168.49.20**

Il propose donc l'accès à deux sites:
- Un intranet avec le nom de domaine **intra.site.lan**. L'intranet n'est accessible qu'aux utilisateurs avec une IP du réseau de l'entreprise.
- Un site externe avec le nom de domaine **www.site.lan**. Le site est accessible depuis partout.
  
## Serveur DNS

Le serveur DNS tourne avec BIND9, avec l'IP: **192.168.49.18**

Il propose l'accès à une résolution de nom de domaine interne pour pouvoir résoudre **intra.site.lan** et une résolution externe qui dirige donc sur l'IP public du routeur public.


