# Projet d’Interconnexion dans Internet – Système Autonome (AS)

## Présentation du projet
Ce projet s’inscrit dans le cadre de l’unité *Internet et Graphes – 2SN parcours A/R/T*.  
L’objectif est de concevoir et de déployer un **système autonome (AS)** complet proposant des **services d’accès Internet** pour particuliers et entreprises.  

Le réseau mis en place intègre plusieurs fonctionnalités essentielles :
- Routage dynamique entre les différents routeurs du système.
- Gestion de la **sécurité** et des accès internes.
- Mise en place d’un **serveur DNS** et d’un **service DHCP**.
- Déploiement d’un **VPN** entre deux sites d’entreprise.
- Interconnexion de l’AS avec les autres systèmes autonomes développés par les autres groupes.

---

## Architecture générale
L’architecture globale comprend :

- Un **AS principal** jouant le rôle de fournisseur de services réseau.  
- Un **site d’entreprise principal** et un **site secondaire**, reliés par un tunnel VPN.  
- Un **serveur DNS interne** pour la résolution des noms locaux.  
- Un **client particulier** simulant un accès Internet résidentiel.  
- Une **interconnexion inter-AS** avec les autres groupes pour permettre la communication entre entreprises et particuliers.  

*Un schéma d’architecture détaillé est disponible dans le dossier `/docs/`.*

---

## Outils et technologies utilisées
| Outil / Technologie | Rôle |
|----------------------|------|
| **Docker** | Déploiement reproductible et modulaire des services réseau |
| **GitHub** | Gestion du code, des issues et du suivi des tâches |

---

## Installation et déploiement

### Prérequis
- Docker et Docker Compose installés  
- Accès au dépôt GitHub du projet  
- Linux ou MACOS recommandé

Chaque dossier de service contient son propre `README.md` avec les instructions spécifiques (DNS, VPN, routage, etc.).

---

## Structure du dépôt
```
.
├── tests/               # Scripts et résultats de tests
├── docs/                # Documentation et schémas d’architecture
├── CODE_GUIDELINES.md   # Règles de développement et de documentation
└── README.md            # Présentation du projet
```

---

## Méthodologie de travail
Afin de faciliter la collaboration, nous avons adopté une approche de travail inspirée de la méthodologie Agile :

- **Réunions toutes les deux semaines** pour faire le point sur l’avancement et les choix techniques.  
- **Issues GitHub** utilisées pour suivre les tâches, les décisions et les responsabilités.  
- **Branche par fonctionnalité** pour assurer un développement parallèle propre et traçable.  
- Chaque issue se conclut par :
  - un `README.md` documenté,  
  - des tests de validation,  
  - une procédure de déploiement minimale.  

---

## Équipe et répartition des rôles
| Membre | Rôle principal | Responsabilités |
|--------|----------------|----------------|
| Achille | x | x |
| Arthur | x | x |
| Lilian | x | x |
| Louan | x | x |
| Paul | x | x |
| Louis | x | x |

---

## Code Guidelines
Les règles de développement, de documentation et de versionnement sont détaillées dans le fichier [`CODE_GUIDELINES.md`](./CODE_GUIDELINES.md).  
Elles couvrent :
- L’organisation du code et des dossiers  
- Les conventions Git / GitHub (branches, commits, issues)  
- Les tests et la documentation  
- Les bonnes pratiques de traçabilité et de maintenance  

---

## Références
- **Sujet officiel** : *Projet d’Interconnexion dans Internet – 2SN 2025-2026*  
- [Documentation Docker](https://docs.docker.com)  


