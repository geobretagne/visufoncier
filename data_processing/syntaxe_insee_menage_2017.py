# -*- coding: utf-8 -*-
"""
Created on Mon Jun 10 14:36:34 2024

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

# URL du fichier Excel depuis l'INSEE pour l'année 2017
url_2017 = "https://www.insee.fr/fr/statistiques/fichier/4515503/base-ccx-coupl-fam-men-2017.zip"

# Chemin complet vers le dossier Téléchargements
downloads_path = os.path.expanduser("~/Downloads")

# Chemin complet du fichier ZIP à télécharger
zip_file_path_2017 = os.path.join(downloads_path, "base-cc-coupl-fam-men-2017_xlsx.zip")

# Télécharger le fichier ZIP
urllib.request.urlretrieve(url_2017, zip_file_path_2017)

# Extraire le contenu du fichier ZIP
with zipfile.ZipFile(zip_file_path_2017, 'r') as zip_ref:
    zip_ref.extractall(downloads_path)

# Lire l'onglet "COM_2017" du fichier Excel
excel_file_path_2017 = os.path.join(downloads_path, "base-cc-coupl-fam-men-2017.xlsx")
df_2017 = pd.read_excel(excel_file_path_2017, sheet_name="COM_2017", skiprows=5)

# Renommer les colonnes en minuscules
df_2017.columns = map(str.lower, df_2017.columns)

# Convertir les données de la colonne 'reg' en type numérique
df_2017['reg'] = pd.to_numeric(df_2017['reg'], errors='coerce')

# Filtrer sur reg=53 (région Bretagne)
df_filtered_2017 = df_2017[df_2017['reg'] == 53]

# Conserver uniquement la variable 'C17_MEN'
df_filtered_2017 = df_filtered_2017[['codgeo', 'reg', 'dep', 'libgeo', 'c17_men']]

# Enregistrer les données filtrées dans un nouveau fichier CSV
filtered_csv_file_path_2017 = os.path.join(downloads_path, "donnees_menages_2017.csv")
df_filtered_2017.to_csv(filtered_csv_file_path_2017, index=False)

print("Données de l'INSEE pour l'année 2017 filtrées et enregistrées dans", filtered_csv_file_path_2017)

# Chargement dans la BDD
# Paramètres de connexion PostgreSQL via des variables d'environnement
host = os.getenv("PG_HOST")
dbname = os.getenv("PG_DBNAME")
user = os.getenv("PG_USER")
password = os.getenv("PG_PASSWORD")
port = os.getenv("PG_PORT")


# Connexion à la base de données PostgreSQL via SQLAlchemy
try:
    engine = create_engine(f'postgresql://{user}:{password}@{host}:{port}/{dbname}?client_encoding=UTF8')
    print("Connexion à la base de données PostgreSQL réussie")
except Exception as e:
    print(f"Erreur lors de la connexion à la base de données : {e}")
    exit(1)

# Lire le fichier CSV filtré
try:
    df_filtered= pd.read_csv(filtered_csv_file_path_2017)
    print("Données CSV chargées avec succès")
except Exception as e:
    print(f"Erreur lors de la lecture du fichier CSV : {e}")
    exit(1)

# Définir les noms et types de colonnes selon la table PostgreSQL
dtype = {
    'codgeo': 'str',
    'reg': 'int',
    'dep': 'int',
    'libgeo': 'str',
    'c17_men': 'float'
}

# Assurer la correspondance des types dans le DataFrame
df_filtered = df_filtered.astype(dtype)

# Insérer les données dans la table PostgreSQL (sans recréer la table)
try:
    df_filtered.to_sql('insee_menage_20172', engine, schema='visufoncier', if_exists='replace', index=False)
    print("Données importées dans la base PostgreSQL")
except Exception as e:
    print(f"Erreur lors de l'insertion des données dans PostgreSQL : {e}")