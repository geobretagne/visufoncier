# Procédure pour le Traitement des Données GPU sur QGIS

## 0. Lancer la vue matérialisée 
- visufoncier.mos_foncier_agrege_enaf_view via la syntaxe 4_MOSxPLU.sql

## 1. Téléchargement et Installation de FileZilla
- Allez sur le site officiel de [FileZilla](https://filezilla-project.org/).
- Téléchargez la version appropriée pour votre système d'exploitation (Windows, macOS, Linux).
- Installez le logiciel en suivant les instructions à l'écran.

## 2. Téléchargement du Fichier `zone_du.gpkg`
- Ouvrez FileZilla après l'installation.
- Suivez les étapes de connexion décrites dans le document `Manuel_export_massif.pdf` disponible sur le [Géoportail de l'urbanisme](https://www.geoportail-urbanisme.gouv.fr/image/Manuel_export_massif.pdf).
- Accédez au répertoire `/pub/export-wfs/latest/gpkg/wfs_du`.
- Téléchargez le fichier `zone_du.gpkg` sur votre ordinateur.

## 3. Ouverture de QGIS
- Lancez QGIS version 3.34 ou supérieure.

## 4. Changement du Système de Coordonnées
- Allez dans le menu `Projet`.
- Sélectionnez `Propriétés`.
- Dans l’onglet `Système de coordonnées`, recherchez `EPSG:2154` ou `Lambert-93`.
- Sélectionnez-le et cliquez sur `OK`.

## 5. Charger les données du GPU zone_du.gpkg
- Choisir les couches de données : zone_urba, prescription_surf, secteur_cc

## 6. Connexion à la Base de Données PostgreSQL
- Dans QGIS, allez dans le menu `DB Manager` (Gestionnaire de base de données).
- Connectez-vous à la base de données PostgreSQL `geobretagne` :
  - Cliquez sur `Add PostGIS Layer` (Ajouter une couche PostGIS).
  - Remplissez les informations nécessaires (hôte, base de données, utilisateur, mot de passe) et testez la connexion.

## 7. Chargement des Tables Utiles
- Dans le `DB Manager`, trouvez et chargez les tables nécessaires pour le modèle :
  - `ign.express_commune`
  - La vue `visufoncier.mos_foncier_agrege_enaf_view`

## 10. Ignorer les Entités Non Valides
- Allez dans le menu `Options` de QGIS.
- Sélectionnez l'onglet `Traitement`.
- Cochez l'option `Ignorer les entités non valides` pour s'assurer que les géométries non valides ne sont pas prises en compte dans les traitements.
  
## 9. Téléchargement du Modèle `mos_gpu_2`
- Télécharger le modèle `mos_gpu_2` dans ce dossier
  
## 10. Lancement du Modèle
- Dans la partie Traitement de QGIS, allez dans `Modèle` et charger le modèle `mos_gpu_2`.
- Renseignez les champs à remplir avec les couches de données appropriées.
- Laissez vides les couches temporaires de résultat.

## 11. Lancement du Traitement
- Après avoir rempli les champs nécessaires, lancez le traitement.
- **Temps approximatif : 48 minutes.**

## 12. Suivi du Traitement
- Surveillez la progression du traitement.
- **Note :** Il peut y avoir des erreurs de géométries invalides qui seront ignorées pendant la reprojection des données du GPU en EPSG:2154. De plus, des erreurs peuvent survenir concernant l'importation de l'ID dans PostgreSQL. Ces erreurs peuvent être ignorées si les données sont correctement traitées par la suite.

## 13. Post-traitement
- Rendez vous sur PostgreSQL pour créer les analayses de données ajustées via la syntaxe 4_PLUxMOS

