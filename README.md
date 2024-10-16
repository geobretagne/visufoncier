# Visufoncier

## Description
Visufoncier est un tableau de bord basé sur Superset et PostgreSQL, conçu pour visualiser et analyser les données foncières de la région Bretagne. Il offre une vue détaillée des flux de consommation, d'artificialisation et de désartificialisation des sols, ainsi que des analyses croisées avec les documents d'urbanisme et d'autres données territoriales.

## Fonctionnalités principales
- Intégration des données OCS GE NG, MOS, INSEE et fichiers fonciers du CEREMA.
- Croisement avec les documents d'urbanisme (PLU, cartes communales, zones de prescription).
- Visualisation des flux fonciers (artificialisation, consommation, renaturation).
- Analyse des données à différents niveaux (Régional, Départemental, SCOT, EPCI, Communal).
- Cartographies interactives des territoires et des zones d'étude.

## Accéder à l'outil
Cliquez sur ce lien pour accéder à l'application Visufoncier : [Visufoncier](https://geobretagne.fr/app/visufoncier)

## Utilisation

### Sélectionner un territoire
L'utilisateur peut choisir le territoire qu'il souhaite analyser (Régional, Départemental, SCOT, EPCI, ou Communal) en accédant à la page d'accueil et en appliquant les filtres. 

### Explorer les données
L'outil offre plusieurs types d'analyses, notamment :

- **Consommation** : Analyse des flux de consommation, surface artificialisée, etc.
- **Artificialisation** : Analyse des flux de couverture et d'usage des sols.
- **Cartographies** : Cartes interactives présentant les résultats des analyses.

### Documentation
Pour en savoir plus sur les fonctionnalités et l'utilisation de l'outil, consultez la documentation complète dans le répertoire `documentation` :
[Tutoriel utilisateur](https://github.com/geobretagne/visufoncier/blob/main/documentation/tutoriel.md)

### Problèmes et suggestions
Si vous rencontrez des problèmes ou si vous avez des suggestions pour améliorer l'outil, n'hésitez pas à créer un ticket dans l'onglet **Issues**. [Ticket](https://github.com/geobretagne/visufoncier/issues)

### Licence
Ce projet est sous licence MIT. Consultez le fichier `LICENSE` pour plus d'informations.

## Installation (optionnel)
Si vous souhaitez installer et configurer Visufoncier localement, suivez les étapes suivantes :

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
