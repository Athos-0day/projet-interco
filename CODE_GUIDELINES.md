# Projet Interconnexion

## Code Guidelines

### Objectif
L’objectif de cette section est d’assurer une cohérence dans la manière de développer, documenter et déployer les différentes tâches du projet.  
Chaque membre est responsable de la partie qu’il implémente et des choix techniques faits (ex : protocole de routage) jusqu’à la documentation et aux tests associés.

---

### Structure et organisation du code
- Chaque fonctionnalité doit être développée dans un dossier dédié, contenant un fichier `README.md` décrivant :
  - son rôle dans le projet,  
  - ses dépendances (images Docker, scripts, paquets, etc.),
  - les choix techniques associés  
  - la méthode de déploiement (commande `docker run`, `docker-compose`, ou autre).  
- Les noms de fichiers, variables et dossiers doivent être explicites et cohérents.  

---

### Bonnes pratiques Git / GitHub
- Chaque fonctionnalité ou correction est développée sur une **branche dédiée**, liée à une issue (ex : `feature/vpn-setup`, `fix/dhcp-config`). (Pas obligatoire) 
- Les **commits** doivent être courts, clairs et descriptifs (ex : `Add OSPF configuration for AS1 router`).  
- Les **issues GitHub** servent à :
  - décrire la tâche à réaliser,  
  - suivre l’avancement,  
  - attribuer un responsable,  
  - documenter les choix faits.  

---

### Documentation et tests
- Chaque issue doit se conclure par :
  - un `README.md` documenté,  
  - des **tests** ou captures prouvant le bon fonctionnement,  
  - une **procédure de déploiement minimale** (script, commande ou fichier Docker).  
- Les configurations doivent être testées dans un environnement isolé avant intégration à l’infrastructure principale.  
- Les dépendances logicielles (versions, images Docker, bibliothèques, etc.) seront mentionnés  

---

### Qualité et traçabilité
- Les décisions techniques importantes doivent être documentées dans le dépôt (`/docs` ou via issues GitHub).  
- Les fichiers générés automatiquement (logs, binaires, etc.) doivent être exclus avec `.gitignore`.  
- Les preuves de bon fonctionnement (captures Wireshark, résultats de ping, tables de routage, etc.) peuvent être stockées dans le dossier `/tests`.  

---

### Organisation et communication
- Le suivi du projet se fait via GitHub (issues, branches, pull requests).  
- Des réunions d’équipe sont tenues **toutes les deux semaines** pour :
  - faire le point sur les tâches réalisées,  
  - identifier les problèmes rencontrés,  
  - planifier les étapes suivantes.  
- Les décisions et comptes rendus sont centralisés dans le dépôt.

---

## Esprit général
L’objectif n’est pas seulement d’obtenir un résultat fonctionnel, mais de produire un code **lisible, réutilisable et reproductible**.  


