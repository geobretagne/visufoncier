# Syntaxe Python 

Ce projet nécessite un environnement Python pour le traitement des données de l'emploi, ménage, population, fusion de communes de l'INSEE.

## Prérequis

- **Python 3.12.4** : Assurez-vous d’avoir cette version installée.

## Installation

## Naviguer vers le dossier du projet

   Accédez au dossier contenant le projet :

   ```bash
   cd chemin/vers/le/sous-dossier
 ```
## Créer et activer un environnement virtuel

Créez un environnement virtuel appelé `envfoncier` :

```bash
python3 -m venv envfoncier

.\envfoncier\Scripts\activate

```
## Installer les dépendances

Installez les bibliothèques nécessaires à partir du fichier requirements.txt :

```bash
pip install -r requirements.txt
```

## Configuration de la connexion PostgreSQL

Créez un fichier .env à la racine du projet pour stocker les informations de connexion à votre base de données PostgreSQL. Voici les variables à ajouter dans le fichier .env :

```bash
PG_HOST="adresse_serveur"
PG_DBNAME="nom_base"
PG_USER="nom_utilisateur"
PG_PASSWORD="mot_de_passe"
PG_PORT="5432"

```
