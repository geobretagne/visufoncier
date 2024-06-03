-- ==========================================================
-- Ce fichier contient toutes les requêtes SQL relatives aux données du MOS,
-- y compris les requêtes pour la création de tables, l'insertion de données
-- Chaque section est commentée pour faciliter la compréhension et la maintenance du code.


-- ==========================================================
--Téléchargement des données bruts du MOS (Lien : https://geobretagne.fr/geonetwork/srv/fre/catalog.search#/metadata/b783e48b-c811-4504-900a-4b3d8e49888e)
--Mise en BDD dans un schéma "geobretagne"
--Nom de la table :mos_foncier


-- ==========================================================
--Début du traitement des données
-- ==========================================================


-- ==========================================================
-- Création d'une table 'mos_foncier_agrege' qui agrège les données foncières télécharger à l'étape précédente par commune et par code,
-- calcule la surface totale des géométries, génère des identifiants uniques, et transforme les géométries dans le système de coordonnées EPSG:2154.

CREATE TABLE visufoncier.mos_foncier_agrege
TABLESPACE pg_default
AS
SELECT 
    row_number() OVER () AS id,
    t.geom,
    t.codegeo_mos,
    t.nom_commune_mos,
    t.code4_2021,
    t.code4_2011,
    t.nature_2021,
    t.nature_det_2021,
    t.nature_2011,
    t.nature_det_2011,
    t.surface_calc_m2,
    t.surface_calc_m2 / 10000 AS surface_calc_ha -- Conversion de m² à hectares
FROM (
    SELECT 
        mos_foncier.nom_commun AS nom_commune_mos,
        mos_foncier.code4_2021::bigint AS code4_2021, -- Conversion en bigint
        mos_foncier.code4_2011::bigint AS code4_2011, -- Conversion en bigint
        mos_foncier.code_insee AS codegeo_mos,
        regroup_2021 AS nature_2021,  -- Ajout du champ regroup_2021
        lib4_2021 AS nature_det_2021,  -- Ajout du champ lib4_2021
        regroup_2011 AS nature_2011,   -- Ajout du champ regroup_2011
        lib4_2011 AS nature_det_2011,  -- Ajout du champ lib4_2011
        st_area(st_transform((st_dump(st_union(mos_foncier.geom))).geom, 2154)) AS surface_calc_m2,
        st_transform((st_dump(st_union(mos_foncier.geom))).geom, 2154) AS geom
    FROM 
        geobretagne.mos_foncier
    GROUP BY 
        mos_foncier.code_insee, 
        mos_foncier.nom_commun, 
        mos_foncier.code4_2021, 
        mos_foncier.code4_2011,
        regroup_2021,   -- Ajout au GROUP BY pour les nouveaux champs
        lib4_2021,
        regroup_2011,
        lib4_2011
) t;


--Création d'un index géographique sur la table 
CREATE INDEX idx_mos_foncier_agrege_geom ON visufoncier.mos_foncier_agrege USING gist (geom);

--Création d'index pour améliorer les performances de l'affichage dans le tdb superset
-- Index sur flux_conso
CREATE INDEX idx_flux_conso ON visufoncier.mos_foncier_agrege (flux_conso);

-- Index combiné pour les colonnes 2011
CREATE INDEX idx_2011 ON visufoncier.mos_foncier_agrege (code4_2011, nature_2011, enaf_conso_2011);

-- Index combiné pour les colonnes 2021
CREATE INDEX idx_2021 ON visufoncier.mos_foncier_agrege (code4_2021, nature_2021, enaf_conso_2021);


--Commentaire

 COMMENT ON TABLE visufoncier.mos_foncier_agrege  IS
  'Table du MOS 2011-2021. Crée à partir des données brutes du MOS géobretagne. Reliée au tableau de bord superset. Table principale pour les analyses';

--Fin de création de la table
-- ==========================================================

-- ==========================================================
--Création des variables enaf vs conso / Artificialisees vs artificialisees en partie vs non artificialisees sur 2011 et 2021
-- ==========================================================

--Ajout des colonnes
ALTER TABLE visufoncier.mos_foncier_agrege
ADD COLUMN enaf_conso_2021 VARCHAR,
ADD COLUMN enaf_conso_2011 VARCHAR,
ADD COLUMN artificialisees_2021 VARCHAR,
ADD COLUMN artificialisees_2011 VARCHAR;

--Update
UPDATE visufoncier.mos_foncier_agrege
SET 
    enaf_conso_2021 = CASE 
        WHEN code4_2021 IN (1112, 1113, 1114, 1115, 1122, 1211, 1212, 1213, 1217, 1218, 1219, 1221, 1222, 1223, 1224, 1226, 1227, 1228, 1231, 1232, 1233, 1234, 1235, 1236, 1331, 1332, 1333, 1335, 1411, 1413, 1414, 1421, 1220, 1225, 1412, 3252) THEN 'conso'
        WHEN code4_2021 IN (1131, 1334, 1423, 2121, 2511, 3251, 3261, 3311, 3321, 5121, 5131, 5231, 1311) THEN 'enaf'
        ELSE NULL
    END,
    enaf_conso_2011 = CASE 
        WHEN code4_2011 IN (1112, 1113, 1114, 1115, 1122, 1211, 1212, 1213, 1217, 1218, 1219, 1221, 1222, 1223, 1224, 1226, 1227, 1228, 1231, 1232, 1233, 1234, 1235, 1236, 1331, 1332, 1333, 1335, 1411, 1413, 1414, 1421, 1220, 1225, 1412, 3252) THEN 'conso'
        WHEN code4_2011 IN (1131, 1334, 1423, 2121, 2511, 3251, 3261, 3311, 3321, 5121, 5131, 5231, 1311) THEN 'enaf'
        ELSE NULL
    END,
    artificialisees_2021 = CASE 
        WHEN code4_2021 IN (1112, 1113, 1114, 1115, 1122, 1211, 1212, 1213, 1217, 1218, 1219, 1221, 1222, 1223, 1224, 1227, 1228, 1231, 1232, 1233, 1235, 1236, 1333, 1411, 1421, 1220, 1225, 3252) THEN 'artificialisees'
        WHEN code4_2021 IN (1226, 1234, 1331, 1332, 1335, 1413, 1414) THEN 'artificialisees en partie'
        WHEN code4_2021 IN (1131, 2121, 3251, 3261, 3311, 3321, 5121, 5131, 5231, 1423, 2511, 1311, 1412) THEN 'non artificialisees'
        ELSE NULL
    END,
    artificialisees_2011 = CASE 
        WHEN code4_2011 IN (1112, 1113, 1114, 1115, 1122, 1211, 1212, 1213, 1217, 1218, 1219, 1221, 1222, 1223, 1224, 1227, 1228, 1231, 1232, 1233, 1235, 1236, 1333, 1411, 1421, 1220, 1225, 3252) THEN 'artificialisees'
        WHEN code4_2011 IN (1226, 1234, 1331, 1332, 1335, 1413, 1414) THEN 'artificialisees en partie'
        WHEN code4_2011 IN (1131, 2121, 3251, 3261, 3311, 3321, 5121, 5131, 5231, 1423, 2511, 1311, 1412) THEN 'non artificialisees'
        ELSE NULL
    END;

--Fin de création des variables
-- ==========================================================
--Calcul des flux

-- Ajouter une nouvelle colonne nommée flux_conso dans la table. Si flux_conso=1 alors flux de consommation.
ALTER TABLE visufoncier.mos_foncier_agrege
ADD COLUMN flux_conso integer;

-- Calcul si oui ou non flux en mettant à jour la colonne flux_conso
UPDATE visufoncier.mos_foncier_agrege
SET flux_conso = CASE WHEN enaf_conso_2011 = 'enaf' AND enaf_conso_2021 = 'conso' THEN 1 ELSE 0 END;


-- Ajouter une nouvelle colonne nommée flux_artif dans la table. Si flux_artif=1 alors flux d'artificialisation.
ALTER TABLE visufoncier.mos_foncier_agrege
ADD COLUMN flux_artif integer;

-- Calcul si oui ou non flux en mettant à jour la colonne flux_conso
UPDATE visufoncier.mos_foncier_agrege
SET flux_artif = CASE WHEN artificialisees_2011 = 'non artificialisees' AND (artificialisees_2021 = 'artificialisees' OR artificialisees_2021 = 'artificialisees en partie') THEN 1 ELSE 0 END;


-- Ajouter une nouvelle colonne nommée flux_conso dans la table. Si flux_conso=1 alors flux de consommation.
ALTER TABLE visufoncier.mos_foncier_agrege
ADD COLUMN flux_renaturation integer;

-- Calcul si oui ou non flux en mettant à jour la colonne flux_conso
UPDATE visufoncier.mos_foncier_agrege
SET flux_renaturation = CASE WHEN enaf_conso_2021 = 'enaf' AND enaf_conso_2011 = 'conso' THEN 1 ELSE 0 END;


--Fin calcul des flux

-- ==========================================================
--Partie SCOT EPCI COMMUNES
-- ==========================================================

--Téléchargement d'ADMIN EXPRESS (creer script python)

--Crée un schéma IGN (creer script python)

--Chargement de la table commune (syntaxe à ajouter) (creer script python)
--Appeler la table "express_commune"(creer script python)

--Chargement de la table EPCI(syntaxe à ajouter) (creer script python)
--Appeler la table "express_EPCI" (creer script python)

-- Renommer la colonne 'code_siren' en 'code_epci'
ALTER TABLE ign.express_epci
RENAME COLUMN code_siren TO code_epci;

-- Renommer la colonne 'nom' en 'nom_epci'
ALTER TABLE ign.express_epci
RENAME COLUMN nom TO nom_epci;

-- Renommer la colonne 'nature' en 'type_epci'
ALTER TABLE ign.express_epci
RENAME COLUMN nature TO type_epci;


--Faire le lien entre la table des communes 

-- 1. Ajoute de colonne à la table 'visufoncier.mos_foncier_agrege'

ALTER TABLE visufoncier.mos_foncier_agrege
ADD COLUMN insee_com VARCHAR,
ADD COLUMN nom_commune VARCHAR,
ADD COLUMN siren_epci VARCHAR,
ADD COLUMN insee_dep VARCHAR,
ADD COLUMN insee_reg VARCHAR;

-- 2. Mettre à jour les colonnes en utilisant une jointure avec la table 'ign.express_epci'

UPDATE visufoncier.mos_foncier_agrege
SET 
    insee_com = ign.express_commune.insee_com,
    nom_commune = ign.express_commune.nom,
    siren_epci = ign.express_commune.siren_epci,
    insee_dep = ign.express_commune.insee_dep,
    insee_reg = ign.express_commune.insee_reg
FROM 
    ign.express_commune
WHERE 
    visufoncier.mos_foncier_agrege.codegeo_mos = ign.express_commune.insee_com;

--Faire le lien entre la table EPCI


-- 1. Ajouter la colonne 'nom_epci' à la table 'visufoncier.mos_foncier_agrege'
ALTER TABLE visufoncier.mos_foncier_agrege
ADD COLUMN nom_epci VARCHAR;

-- 2. Mettre à jour la colonne 'nom_epci' en utilisant une jointure avec la table 'ign.express_epci'
UPDATE visufoncier.mos_foncier_agrege
SET nom_epci = ign.express_epci.nom_epci
FROM ign.express_epci
WHERE visufoncier.mos_foncier_agrege.siren_epci = ign.express_epci.code_epci;


--Téléchargement des données SCOT : (creer script python)
--https://static.data.gouv.fr/resources/schema-de-coherence-territoriale-scot-donnees-sudocuh-dernier-etat-des-lieux-annuel-au-31-decembre-2023/20240308-153958/2023-sudocuh-qv-scot-bilan-annuel.xlsx
--J'ai selectionné dans le excel un seul onglet et retirer des lignes d'entete
--J'ai renommé les colonnes et changer l'encodage dans le csv

--Ajout des données à la BDD 
CREATE TABLE visufoncier.sudocuh_scot (
    id_scot INT,
    nom_scot VARCHAR(255),
    siren_epci BIGINT,
    insee_com VARCHAR(10),
    nom_com VARCHAR(255),
    pop_municipale VARCHAR(255),
    pop_totale VARCHAR(255),
    superficie_insee NUMERIC(10, 2),
    zone_blanche VARCHAR(3),
    scot_opposable VARCHAR(3)
);

--Ajout du CSV à la BDD (creer script python)
--Importation
COPY visufoncier.scot (id_scot, nom_scot, siren_epci, insee_com, nom_com, pop_municipale, pop_totale, superficie_insee, zone_blanche, scot_opposable)
FROM '/path/to/your/file.csv'
DELIMITER ';'
CSV HEADER;

 COMMENT ON TABLE visufoncier.sudocuh_scot  IS
  'Table importée des données suDocUH pour jointure avec les données du MOS';
--Faire le lien entre la table SCOT

-- Ajouter une colonne nom_scot à visufoncier.mos_foncier_agrege
ALTER TABLE visufoncier.mos_foncier_agrege
ADD COLUMN nom_scot VARCHAR(255);

-- Mettre à jour la colonne nom_scot en effectuant une jointure
UPDATE visufoncier.mos_foncier_agrege v
SET nom_scot = s.nom_scot
FROM visufoncier.sudocuh_scot s
WHERE v.insee_com = s.insee_com;


--Syntaxe de mise à jour des communes fusionnées depuis la mise en ligne des données du MOS
UPDATE visufoncier.mos_foncier_agrege
SET insee_com = '35062',
    nom_commune = 'La Chapelle-Fleurigné',
    siren_epci = '200072452',
    insee_dep = '35',
    insee_reg = '53',
    nom_epci = 'CA Fougères Agglomération',
    nom_scot = 'SCOT DU PAYS DE FOUGERES'
WHERE nom_commune_mos = 'Fleurigné';

--Modification Fusion d'EPCI



--Modification Fusion SCOT



--Maintenant creer une table pour nom_commune, nom_epci, nom_scot, juste avec un id pour avoir une table simple pour les filtres sur superset

CREATE INDEX idx_nom_commune_nom_epci_nom_scot_insee_com
ON visufoncier.mos_foncier_agrege (nom_commune, nom_epci, nom_scot, insee_com);


-- Créer la table mos_commune
CREATE TABLE visufoncier.mos_commune (
    id SERIAL PRIMARY KEY,
    nom_commune VARCHAR(255) NOT NULL
);

-- Créer la table mos_epci
CREATE TABLE visufoncier.mos_epci (
    id SERIAL PRIMARY KEY,
    nom_epci VARCHAR(255) NOT NULL
);

-- Créer la table mos_scot
CREATE TABLE visufoncier.mos_scot (
    id SERIAL PRIMARY KEY,
    nom_scot VARCHAR(255) NOT NULL
);
-- Insérer les noms de communes uniques dans mos_commune
INSERT INTO visufoncier.mos_commune (nom_commune)
SELECT DISTINCT nom_commune
FROM visufoncier.mos_foncier_agrege
WHERE nom_commune IS NOT NULL;

-- Insérer les noms de EPCI uniques dans mos_epci
INSERT INTO visufoncier.mos_epci (nom_epci)
SELECT DISTINCT nom_epci
FROM visufoncier.mos_foncier_agrege
WHERE nom_epci IS NOT NULL;

-- Créer un index sur nom_commune dans la table mos_commune
CREATE INDEX idx_nom_commune ON visufoncier.mos_commune (nom_commune);

-- Créer un index sur nom_epci dans la table mos_epci
CREATE INDEX idx_nom_epci ON visufoncier.mos_epci (nom_epci);

-- Créer un index sur nom_scot dans la table mos_scot
CREATE INDEX idx_nom_scot ON visufoncier.mos_scot (nom_scot);


COMMENT ON TABLE visufoncier.mos_scot IS
  'Table avec le nom des SCOT pour les filtres. Reliée au tableau de bord superset. Provient des données SuDocUH';
 COMMENT ON TABLE visufoncier.mos_epci IS
  'Table avec le nom des EPCI pour les filtres. Reliée au tableau de bord superset. Provient des données Adminexpress';
 COMMENT ON TABLE visufoncier.mos_commune IS
  'Table avec le nom des communes pour les filtres. Reliée au tableau de bord superset. Provient des données Adminexpress';

