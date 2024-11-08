
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TRAITEMENT DES DONNÉES DU MODE D'OCCUPATION DU SOL BRETON SUR PostgreSQL --
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Avant tout, charger les données brutes du MOS dans un schéma de votre base de données.
-- Selon la livraison, les données peuvent être brutes ou déjà agrégées (agrégation effectuée sur le champ dc_mos : regroupement des géométries par le code4 des deux millésimes + code insee).
-- Veuillez adapter le traitement en fonction du format de vos données sources.

-- Vérifier la présence du code INSEE dans les données MOS. Si des codes sont manquants, il est nécessaire d'effectuer une intersection avec les couches admin_express pour les compléter.
-- Cette opération permet de s'assurer que chaque géométrie est bien associée à une commune via le code INSEE.
-- Pour vérifier le nombre de codes INSEE manquants dans votre table actuelle, vous pouvez utiliser une requête de comptage sur les champs correspondants.

SELECT COUNT(*) FROM votreschema.mos_foncier WHERE code_insee IS NULL;

-- Si des manquants sont détectés (+de 100), vous pouvez utiliser une jointure spatiale avec la couche PCI_vecteur pour récupérer les codes INSEE manquants.
-- Veuillez vous référer aux syntaxes d'intersection utilisées dans l'OCS GE pour plus de précision.

-- Le nom des communes provient de la couche admin_express pour garantir la cohérence avec les filtres.
-- Cela est important pour les analyses et les filtres Superset.


--SI LA TABLE BRUTE N'EST PAS AGREGE PAR CODE4 ET CODE_INSEE
-- Créer la table agrégée à partir de la table brute téléchargée du MOS.
-- Cette agrégation regroupe les géométries par commune, ainsi que par "code4_2021" et "code4_2011".
-- Elle permet de travailler sur un nombre restreint de polygones, car dans la table brute, le découpage est parcellaire (basé sur le cadastre).

-- Pour la prochaine vague de données (exemple : 2021-2024), il faudra créer une nouvelle table
-- dans le schéma "geobretagne" nommée "mos_foncier_agrege_2011_2021_2021_2024" et adapter les requêtes
-- en remplaçant les "_2021" et "_2011" par les nouveaux millésimes correspondants.

-- Créer une nouvelle table "mos_foncier_agrege_2011_2021" dans le schéma "visufoncier"
--Adapter le nom des variables dans le select si changement. 

CREATE TABLE visufoncier.mos_foncier_agrege_2011_2021 AS
SELECT
    code_insee AS codegeo_mos,                -- Code INSEE de la commune
    nom_commun AS nom_commune_mos,            -- Nom de la commune
    code4_2021,                               -- Code de la catégorie d'occupation du sol en 2021
    code4_2011,                               -- Code de la catégorie d'occupation du sol en 2011
    regroup_2021 AS nature_2021,              -- Nature de l'occupation du sol en 2021
    lib4_2021 AS nature_det_2021,             -- Détail de la nature de l'occupation du sol en 2021
    regroup_2011 AS nature_2011,              -- Nature de l'occupation du sol en 2011
    lib4_2011 AS nature_det_2011,             -- Détail de la nature de l'occupation du sol en 2011
    ST_Transform((ST_Dump(ST_Union(geom))).geom, 2154) AS geom -- Union des géométries avec transformation au format EPSG:2154
FROM geobretagne.mos_foncier
GROUP BY code_insee, nom_commun, code4_2021, code4_2011, regroup_2021, lib4_2021, regroup_2011, lib4_2011;

--SI LA TABLE BRUTE EST AGREGEE, partir de celle ci pour les étapes suivantes.

--Déclarer le type de geom et le scr
ALTER TABLE visufoncier.mos_foncier_agrege
ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 2154)
USING ST_Multi(ST_SetSRID(geom, 2154));

--Création d'index sur la table 
CREATE INDEX IF NOT EXISTS idx_mos_foncier_agrege_2011_2021_geom ON visufoncier.mos_foncier_agrege_2011_2021 USING gist (geom); --Sur la géométrie
CREATE INDEX IF NOT EXISTS idx_mos_foncier_agrege_2011_2021_insee_com ON visufoncier.mos_foncier_agrege_2011_2021 (insee_com); --Sur le code INSEE

-- Ajouter une colonne "fid" comme identifiant unique pour chaque ligne dans la table
ALTER TABLE visufoncier.mos_foncier_agrege_2011_2021 
ADD COLUMN fid SERIAL PRIMARY KEY;  -- Définir "fid" comme clé primaire auto-incrémentée

--Commentaire sur la table 
COMMENT ON TABLE visufoncier.mos_foncier_agrege_2011_2021  IS
'Table du MOS 2011-2021. Crée à partir des données brutes du MOS géobretagne. Table qui permet de lancer les analyses avant d agreger les résultats par commune dans la table mos_foncier_agrege_2011_2021_com qui est la table principale du tdb superset visufoncier';
  
-- Ouverture des droits d'accès sur la table "mos_foncier_agrege_2011_2021" pour permettre la consultation des données

-- Accorder le droit de sélection (SELECT) à l'utilisateur de l'application
-- Cet utilisateur est celui qui lancera les requêtes depuis l'application Superset.
-- Il est important de ne pas accorder des droits excessifs, comme "GRANT ALL", 
-- afin de limiter les permissions uniquement aux opérations nécessaires.
GRANT SELECT ON TABLE visufoncier.mos_foncier_agrege_2011_2021 TO "app-utilisateur";

-- Accorder tous les droits (ALL) à un utilisateur spécifique
-- Cet utilisateur peut avoir besoin de droits supplémentaires pour des opérations variées.
-- Vérifier que cet utilisateur a la responsabilité d'effectuer des modifications sur la table.
GRANT ALL ON TABLE visufoncier.mos_foncier_agrege_2011_2021 TO "utilisateur-avec-droits-complets";

-- Accorder le droit de sélection (SELECT) à un utilisateur utilisé par le serveur web
-- Cet utilisateur est souvent utilisé pour accéder aux données nécessaires.
GRANT SELECT ON TABLE visufoncier.mos_foncier_agrege_2011_2021 TO "utilisateur-web";

--Il faudra accorder ces droits à chaque table utilisée dans visufoncier.

--DEBUT CALCUL INDICATEURS--

-- Modifier la table "mos_foncier_agrege_2011_2021" pour ajouter des colonnes de surface calculée
ALTER TABLE visufoncier.mos_foncier_agrege_2011_2021
ADD COLUMN surface_calc_m2 double precision,  -- Surface calculée en mètres carrés
ADD COLUMN surface_calc_ha double precision;  -- Surface calculée en hectares

-- Mettre à jour les valeurs des nouvelles colonnes de surface calculée
UPDATE visufoncier.mos_foncier_agrege_2011_2021
SET
    surface_calc_m2 = ST_Area(geom),          -- Calculer la surface en mètres carrés à partir de la géométrie
    surface_calc_ha = ST_Area(geom) / 10000;  -- Calculer la surface en hectares

-- Ajout d'une colonne "nom_departement" pour stocker le nom du département
-- Cette colonne doit être personnalisée selon la région concernée
ALTER TABLE visufoncier.mos_foncier_agrege_2011_2021
ADD COLUMN nom_departement VARCHAR;

-- Mise à jour de la colonne "nom_departement" en fonction du code INSEE de la commune
UPDATE visufoncier.mos_foncier_agrege_2011_2021
SET nom_departement = CASE
    WHEN LEFT(insee_com, 2) = '35' THEN 'Ille-et-Vilaine'       -- Code INSEE pour Ille-et-Vilaine
    WHEN LEFT(insee_com, 2) = '22' THEN 'Côtes-d''Armor'       -- Code INSEE pour Côtes-d'Armor
    WHEN LEFT(insee_com, 2) = '56' THEN 'Morbihan'             -- Code INSEE pour Morbihan
    WHEN LEFT(insee_com, 2) = '29' THEN 'Finistère'            -- Code INSEE pour Finistère
END;

-- Ajout des colonnes "millesime_debut" et "millesime_fin" pour stocker les dates des millésimes
-- Ces colonnes doivent également être personnalisées selon les millésimes spécifiques
ALTER TABLE visufoncier.mos_foncier_agrege_2011_2021
ADD COLUMN millesime_debut TIMESTAMP,
ADD COLUMN millesime_fin TIMESTAMP;

-- Mise à jour des colonnes "millesime_debut" et "millesime_fin" avec des valeurs spécifiques
-- Ces colonnes doivent également être personnalisées selon les millésimes spécifiques
UPDATE visufoncier.mos_foncier_agrege_2011_2021
SET millesime_debut = '2011-01-01 00:00:00',  -- Date de début du millésime
    millesime_fin = '2021-01-01 00:00:00';    -- Date de fin du millésime

-- Calcul des indicateurs "enaf_conso" et "artificialisees" (environ 10 minutes de temps de traitement)
-- Ajout de colonnes pour stocker les valeurs de consommation pour les années 2021 et 2011
--Vérifier si pas de changement dans la nomenclature pour la prochaine vague et changer le nom des variables
ALTER TABLE visufoncier.mos_foncier_agrege_2011_2021
ADD COLUMN enaf_conso_2021 VARCHAR,
ADD COLUMN enaf_conso_2011 VARCHAR,

-- Mise à jour des nouvelles colonnes en fonction des codes de classification
UPDATE visufoncier.mos_foncier_agrege_2011_2021
SET 
    -- Attribution de la catégorie "conso" ou "enaf" pour l'année 2021
    enaf_conso_2021 = CASE 
        WHEN code4_2021 IN (1112, 1113, 1114, 1115, 1122, 1211, 1212, 1213, 1217, 1218, 1219, 1221, 1222, 1223, 1224, 1226, 1227, 1228, 1231, 1232, 1233, 1234, 1235, 1236, 1331, 1332, 1333, 1335, 1411, 1413, 1414, 1421, 1220, 1225, 1412, 3252) THEN 'conso'
        WHEN code4_2021 IN (1131, 1334, 1423, 2121, 2511, 3251, 3261, 3311, 3321, 5121, 5131, 5231, 1311) THEN 'enaf'
        ELSE NULL
    END,
    
    -- Attribution de la catégorie "conso" ou "enaf" pour l'année 2011
    enaf_conso_2011 = CASE 
        WHEN code4_2011 IN (1112, 1113, 1114, 1115, 1122, 1211, 1212, 1213, 1217, 1218, 1219, 1221, 1222, 1223, 1224, 1226, 1227, 1228, 1231, 1232, 1233, 1234, 1235, 1236, 1331, 1332, 1333, 1335, 1411, 1413, 1414, 1421, 1220, 1225, 1412, 3252) THEN 'conso'
        WHEN code4_2011 IN (1131, 1334, 1423, 2121, 2511, 3251, 3261, 3311, 3321, 5121, 5131, 5231, 1311) THEN 'enaf'
        ELSE NULL
    END;

-- Ajouter une nouvelle colonne nommée flux_conso dans la table
-- Si flux_conso=1 alors il y a flux de consommation
ALTER TABLE visufoncier.mos_foncier_agrege_2011_2021
ADD COLUMN flux_conso integer;

-- Calculer si oui ou non il y a flux en mettant à jour la colonne flux_conso
UPDATE visufoncier.mos_foncier_agrege_2011_2021
SET flux_conso = CASE 
    WHEN enaf_conso_2011 = 'enaf' AND enaf_conso_2021 = 'conso' THEN 1 
    ELSE 0 
END;

-- Ajouter une nouvelle colonne nommée flux_renaturation dans la table. 
-- Si flux_renaturation=1 alors il y a flux de renaturation.
ALTER TABLE visufoncier.mos_foncier_agrege_2011_2021
ADD COLUMN flux_renaturation integer;

-- Calculer si oui ou non il y a flux en mettant à jour la colonne flux_renaturation
UPDATE visufoncier.mos_foncier_agrege_2011_2021
SET flux_renaturation = CASE 
    WHEN enaf_conso_2021 = 'enaf' AND enaf_conso_2011 = 'conso' 
    THEN 1 
    ELSE 0 
END;

-- Création des index complémentaires pour SUPERSET
CREATE INDEX IF NOT EXISTS idx_flux_conso ON visufoncier.mos_foncier_agrege_2011_2021 (flux_conso);
CREATE INDEX IF NOT EXISTS idx_2011 ON visufoncier.mos_foncier_agrege_2011_2021 (code4_2011, nature_2011, enaf_conso_2011);
CREATE INDEX IF NOT EXISTS idx_2021 ON visufoncier.mos_foncier_agrege_2011_2021 (code4_2021, nature_2021, enaf_conso_2021);
CREATE INDEX IF NOT EXISTS idx_renaturation ON visufoncier.mos_foncier_agrege_2011_2021 (flux_renaturation);



