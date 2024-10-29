# -*- coding: utf-8 -*-
"""
Created on Wed Jun  5 16:51:49 2024

@author: margot
"""

import os
import pandas as pd
import urllib.request
import zipfile
from sqlalchemy import create_engine
from dotenv import load_dotenv  # Importer dotenv pour charger les variables d'environnement

# Charger les variables d'environnement du fichier .env
load_dotenv()

# URL du fichier ZIP depuis l'INSEE - personnaliser l'URL si le lien à changé
url = "https://www.insee.fr/fr/statistiques/fichier/7671867/table_passage_geo2003_geo2024.zip"

# Chemin complet vers le dossier Téléchargements
downloads_path = os.path.expanduser("~/Downloads")

# Chemin complet du fichier ZIP à télécharger
zip_file_path = os.path.join(downloads_path, "table_passage_geo2003_geo2024.zip")

# Télécharger le fichier ZIP
urllib.request.urlretrieve(url, zip_file_path)

# Chemin complet du dossier extrait
extracted_folder_path = os.path.join(downloads_path, "table_passage_geo2003_geo2024")

# Extraire le contenu du fichier ZIP
with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
    zip_ref.extractall(extracted_folder_path)

# Lire l'onglet "Liste des fusions" du fichier Excel
excel_file_path = os.path.join(extracted_folder_path, "table_passage_geo2003_geo2024.xlsx")
df = pd.read_excel(excel_file_path, sheet_name="Liste des fusions", skiprows=5)

# Renommer les colonnes en minuscules
df.columns = map(str.lower, df.columns)

# Filtrer sur les deux premiers caractères de "com_ini" en utilisant la fonction str.startswith
df_filtered = df[df['com_ini'].astype(str).str.startswith(('22', '29', '56', '35'))]

# Enregistrer les données filtrées dans un nouveau fichier CSV
filtered_csv_file_path = os.path.join(downloads_path, "insee_fusioncom.csv")
df_filtered.to_csv(filtered_csv_file_path, index=False, encoding='utf-8')

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
    df_filtered= pd.read_csv(filtered_csv_file_path)
    print("Données CSV chargées avec succès")
except Exception as e:
    print(f"Erreur lors de la lecture du fichier CSV : {e}")
    exit(1)

# Définir les types de colonnes selon la table PostgreSQL
dtype = {
    'annee_modif': 'int',
    'com_ini': 'str',
    'com_fin': 'str',
    'lib_com_ini': 'str',
    'lib_com_fin': 'str'
}

# Assurer la correspondance des types dans le DataFrame
df_filtered = df_filtered.astype(dtype)

# Insérer les données dans la table PostgreSQL (sans recréer la table) -- Attention au nom de la table 
try:
    df_filtered.to_sql('insee_fusioncom', engine, schema='visufoncier', if_exists='replace', index=False)
    print("Données importées dans la base PostgreSQL")
except Exception as e:
    print(f"Erreur lors de l'insertion des données dans PostgreSQL : {e}")