# -*- coding: utf-8 -*-
"""
Created on Wed Jun  5 15:47:09 2024

@author: margo
"""
import os
import pandas as pd
import urllib.request
import zipfile
from sqlalchemy import create_engine
from dotenv import load_dotenv  # Importer dotenv pour charger les variables d'environnement

# Charger les variables d'environnement du fichier .env
load_dotenv()

# URL du fichier Excel depuis l'INSEE
url = "https://www.insee.fr/fr/statistiques/fichier/3698339/base-pop-historiques-1876-2021.xlsx"

# Chemin complet vers le dossier Téléchargements
downloads_path = os.path.expanduser("~/Downloads")

# Chemin complet du fichier à télécharger
excel_file_path = os.path.join(downloads_path, "base-pop-historiques-1876-2021.xlsx")

# Télécharger le fichier Excel
urllib.request.urlretrieve(url, excel_file_path)

# Charger le fichier Excel en spécifiant les en-têtes de colonnes
df = pd.read_excel(excel_file_path, sheet_name=0, header=5)

# Afficher les premières lignes pour vérifier si les données sont correctement chargées


# Renommer les colonnes en minuscules
df.columns = map(str.lower, df.columns)


# Convertir les données de la colonne 'reg' en type numérique
df['reg'] = pd.to_numeric(df['reg'], errors='coerce')
# Afficher le type de données de la colonne 'reg'
print("Type de données de la colonne 'reg' avant la conversion : ", df['reg'].dtype)

# Afficher les valeurs uniques dans la colonne 'reg'
print("Valeurs uniques dans la colonne 'reg' avant la conversion : ", df['reg'].unique())

# Filtrer sur reg=53
# Filtrer sur reg='53' en convertissant la valeur en chaîne de caractères
# Filtrer sur reg='53' en supprimant les espaces blancs autour de la valeur
df_filtered = df[df['reg'] == 53]
print(df.head())

# Afficher les premières lignes des données filtrées pour vérifier si le filtrage fonctionne correctement

# Enregistrer les données filtrées dans un fichier CSV
csv_file_path = os.path.join(downloads_path, "donnees_insee_reg53.csv")
df_filtered.to_csv(csv_file_path, index=False, encoding='utf-8')

# Chargement dans la BDD
# Paramètres de connexion PostgreSQL via des variables d'environnement
host = os.getenv("PG_HOST")
dbname = os.getenv("PG_DBNAME")
user = os.getenv("PG_USER")
password = os.getenv("PG_PASSWORD")
port = os.getenv("PG_PORT")

print(f"Host: {host}, DB Name: {dbname}, User: {user}, Password: {password}, Port: {port}")

# Connexion à la base de données PostgreSQL via SQLAlchemy
try:
    engine = create_engine(f'postgresql://{user}:{password}@{host}:{port}/{dbname}?client_encoding=UTF8')
    print("Connexion à la base de données PostgreSQL réussie")
except Exception as e:
    print(f"Erreur lors de la connexion à la base de données : {e}")
    exit(1)

# Lire le fichier CSV filtré
try:
    df_filtered= pd.read_csv(csv_file_path)
    print("Données CSV chargées avec succès")
except Exception as e:
    print(f"Erreur lors de la lecture du fichier CSV : {e}")
    exit(1)

# Définir les types des colonnes
dtype = {
    'codgeo': 'string',  # txt
    'reg': 'int',        # int
    'dep': 'string',     # txt
    'libgeo': 'string',  # txt
    'pmun2021': 'int',   # int
    'pmun2020': 'int',   # int
    'pmun2019': 'int',   # int
    'pmun2018': 'int',   # int
    'pmun2017': 'int',   # int
    'pmun2016': 'int',   # int
    'pmun2015': 'int',   # int
    'pmun2014': 'int',   # int
    'pmun2013': 'int',   # int
    'pmun2012': 'int',   # int
    'pmun2011': 'int',   # int
    'pmun2010': 'int',   # int
    'pmun2009': 'int',   # int
    'pmun2008': 'int',   # int
    'pmun2007': 'int',   # int
    'pmun2006': 'int',   # int
    'psdc1999': 'int',   # int
    'psdc1990': 'int',   # int
    'psdc1982': 'int',   # int
    'psdc1975': 'int',   # int
    'psdc1968': 'int',   # int
    'psdc1962': 'int',   # int
    'ptot1954': 'int',   # int
    'ptot1936': 'int',   # int
    'ptot1931': 'int',   # int
    'ptot1926': 'int',   # int
    'ptot1921': 'int',   # int
    'ptot1911': 'int',   # int
    'ptot1906': 'int',   # int
    'ptot1901': 'int',   # int
    'ptot1896': 'int',   # int
    'ptot1891': 'int',   # int
    'ptot1886': 'int',   # int
    'ptot1881': 'int',   # int
    'ptot1876': 'int'    # int
}

# Assurer la correspondance des types dans le DataFrame
df_filtered = df_filtered.astype(dtype)

# Insérer les données dans la table PostgreSQL (sans recréer la table)
try:
    df_filtered.to_sql('insee_popmun', engine, schema='visufoncier', if_exists='replace', index=False)
    print("Données importées dans la base PostgreSQL")
except Exception as e:
    print(f"Erreur lors de l'insertion des données dans PostgreSQL : {e}")