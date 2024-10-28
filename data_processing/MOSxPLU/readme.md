# Procédure pour le Traitement des Données GPU sur QGIS

## 1. Lancer la vue matérialisée 
- `visufoncier.mos_foncier_agrege_enaf_view` via la syntaxe `4_MOSxPLU.sql`

## 2. Téléchargement et Installation de FileZilla
- Allez sur le site officiel de [FileZilla](https://filezilla-project.org/).
- Téléchargez la version appropriée pour votre système d'exploitation (Windows, macOS, Linux).
- Installez le logiciel en suivant les instructions à l'écran.

## 3. Téléchargement du Fichier `zone_du.gpkg`
- Ouvrez FileZilla après l'installation.
- Suivez les étapes de connexion décrites dans le document `Manuel_export_massif.pdf` disponible sur le [Géoportail de l'urbanisme](https://www.geoportail-urbanisme.gouv.fr/image/Manuel_export_massif.pdf).
- Accédez au répertoire `/pub/export-wfs/latest/gpkg/wfs_du`.
- Téléchargez le fichier `zone_du.gpkg` sur votre ordinateur.

## 4. Ouverture de QGIS
- Lancez QGIS version 3.34 ou supérieure.

## 5. Changement du Système de Coordonnées
- Allez dans le menu `Projet`.
- Sélectionnez `Propriétés`.
- Dans l’onglet `Système de coordonnées`, recherchez `EPSG:2154` ou `Lambert-93`.
- Sélectionnez-le et cliquez sur `OK`.

## 6. Charger les données du GPU `zone_du.gpkg`
- Choisissez les couches de données : `zone_urba`, `prescription_surf`, `secteur_cc`.

## 7. Connexion à la Base de Données PostgreSQL
- Dans QGIS, allez dans le menu `DB Manager` (Gestionnaire de base de données).
- Connectez-vous à la base de données PostgreSQL `geobretagne` :
  - Cliquez sur `Add PostGIS Layer` (Ajouter une couche PostGIS).
  - Remplissez les informations nécessaires (hôte, base de données, utilisateur, mot de passe) et testez la connexion.

## 8. Chargement des Tables Utiles
- Dans le `DB Manager`, trouvez et chargez les tables nécessaires pour le modèle :
  - `ign.express_commune`
  - La vue `visufoncier.mos_foncier_agrege_enaf_view`

## 9. Ignorer les Entités Non Valides
- Allez dans le menu `Options` de QGIS.
- Sélectionnez l'onglet `Traitement`.
- Cochez l'option `Ignorer les entités non valides` pour s'assurer que les géométries non valides ne sont pas prises en compte dans les traitements.
  
## 10. Téléchargement du Modèle `mos_gpu_2`
- Télécharger le modèle `mos_gpu_2` dans ce dossier.
- Voici un aperçu de la construction du modèle : 
 ![Modèle QGIS](https://github.com/geobretagne/visufoncier/blob/main/documentation/images/model_qgis.png)

## 11. Lancement du Modèle
- Dans la partie Traitement de QGIS, allez dans `Modèle` et chargez le modèle `mos_gpu_2`.
- Renseignez les champs à remplir avec les couches de données appropriées.
- Laissez vides les couches temporaires de résultat.

## 12. Lancement du Traitement
- Après avoir rempli les champs nécessaires, lancez le traitement.
- **Temps approximatif : 48 minutes.**

## 13. Suivi du Traitement
- Surveillez la progression du traitement.
- **Note :** Il peut y avoir des erreurs de géométries invalides qui seront ignorées pendant la reprojection des données du GPU en EPSG:2154. De plus, des erreurs peuvent survenir concernant l'importation de l'ID dans PostgreSQL. Ces erreurs peuvent être ignorées si les données sont correctement traitées par la suite.

## 14. Post-traitement
- Rendez-vous sur PostgreSQL pour créer les analyses de données ajustées via la syntaxe `4_PLUxMOS`.

---

**Attention :** Si besoin de modification du modèle, clic droit sur le nom du modèle et éditez-le. Le modèle est commenté et documenté. 

Documentation pour créer des modèles sous QGIS : [Documentation QGIS](https://docs.qgis.org/3.34/fr/docs/user_manual/processing/modeler.html)
