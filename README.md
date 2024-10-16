# Visufoncier

## Description
Visufoncier est un outil interactif basé sur Superset et PostgreSQL, conçu pour visualiser et analyser les données foncières de la région Bretagne. Il offre une vue détaillée des flux de consommation, d'artificialisation et de désartificialisation des sols, ainsi que des analyses croisées avec les documents d'urbanisme et d'autres données territoriales.

## Fonctionnalités principales
- Intégration des données OCS GE NG, MOS, INSEE et fichiers fonciers du CEREMA.
- Croisement avec les documents d'urbanisme (PLU, cartes communales, zones de prescription).
- Visualisation des flux fonciers (artificialisation, consommation, renaturation).
- Analyse des données à différents niveaux (Régional, Départemental, SCOT, EPCI, Communal).
- Cartographies interactives des territoires et des zones d'étude.

## Accéder à l'outil
Cliquez sur ce lien pour accéder à l'application Visufoncier : [Visufoncier](https://geobretagne.fr/app/visufoncier)

## Installation (optionnel)
Si tu souhaites installer et configurer Visufoncier localement, suis les étapes suivantes :

### Prérequis
- PostgreSQL
- Apache Superset
- GeoServer (pour la publication des données géographiques)
- Python 3.x

### Étapes d'installation
1. **Cloner le dépôt** :
   ```bash
   git clone https://github.com/geobretagne/visufoncier.git
   cd visufoncier

