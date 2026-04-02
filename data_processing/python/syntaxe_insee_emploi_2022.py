# -*- coding: utf-8 -*-
"""
Created on Wed Jun  5 16:51:49 2024
@author: margot

Adaptation pour les données emploi-pop-active 2022 (Bretagne)
"""
import os
import pandas as pd
import urllib.request
import zipfile
from sqlalchemy import create_engine
from dotenv import load_dotenv  # Importer dotenv pour charger les variables d'environnement

# Charger les variables d'environnement du fichier .env
load_dotenv()

# URL du fichier ZIP depuis l'INSEE
url = "https://www.insee.fr/fr/statistiques/fichier/8581444/base-cc-emploi-pop-active-2022_xlsx.zip"

# Chemin complet vers le dossier Téléchargements
downloads_path = os.path.expanduser("~/Downloads")

# Chemin complet du fichier ZIP à télécharger
zip_file_path = os.path.join(downloads_path, "base-cc-emploi-pop-active-2022_xlsx.zip")

# Télécharger le fichier ZIP
urllib.request.urlretrieve(url, zip_file_path)

# Chemin complet du dossier extrait
extracted_folder_path = os.path.join(downloads_path, "base_cc_emploi_2022")

# Extraire le contenu du fichier ZIP
with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
    zip_ref.extractall(extracted_folder_path)

# Lire l'onglet "COM_2022" du fichier Excel
excel_file_path = os.path.join(extracted_folder_path, "base-cc-emploi-pop-active-2022.xlsx")
df = pd.read_excel(excel_file_path, sheet_name="COM_2022", skiprows=5, engine="openpyxl")

# Renommer les colonnes en minuscules
df.columns = map(str.lower, df.columns)

# Conversions numériques (important pour le filtre)
df['reg'] = pd.to_numeric(df['reg'], errors='coerce')

# Filtrer sur la région Bretagne (code 53)
df_filtered = df[df['reg'] == 53].copy()

# Colonnes à conserver
cols = ['codgeo', 'reg', 'dep', 'libgeo', 'p22_emplt']
df_filtered = df_filtered[[c for c in cols if c in df_filtered.columns]]

# Enregistrer les données filtrées dans un nouveau fichier CSV
filtered_csv_file_path = os.path.join(downloads_path, "emploi_2022_bretagne.csv")
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
    df_filtered = pd.read_csv(filtered_csv_file_path)
    print("Données CSV chargées avec succès")
except Exception as e:
    print(f"Erreur lors de la lecture du fichier CSV : {e}")
    exit(1)

# Définir les types de colonnes selon la table PostgreSQL
dtype = {
    'codgeo': 'str',
    'reg': 'int',
    'dep': 'str',
    'libgeo': 'str',
    'p22_emplt': 'float'
}

# Assurer la correspondance des types dans le DataFrame
df_filtered = df_filtered.astype(dtype)

#--ne fonctionne pas, à faire à la main sous postgresql Insérer les données dans la table PostgreSQL (sans recréer la table) -- Attention au nom de la table
try:
    df_filtered.to_sql('insee_emploi_2022', engine, schema='visufoncier', if_exists='replace', index=False)
    print("Données importées dans la base PostgreSQL")
except Exception as e:
    print(f"Erreur lors de l'insertion des données dans PostgreSQL : {e}")