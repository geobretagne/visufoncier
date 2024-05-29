-- ==========================================================
-- Ce fichier contient toutes les requêtes SQL relatives aux données du MOS,
-- y compris les requêtes pour la création de tables, l'insertion de données
-- Chaque section est commentée pour faciliter la compréhension et la maintenance du code.
-- ==========================================================
--Téléchargement des données bruts du MOS (Lien : https://geobretagne.fr/geonetwork/srv/fre/catalog.search#/metadata/b783e48b-c811-4504-900a-4b3d8e49888e)
--Mise en BDD Géobretagne dans un schéma visufoncier
-- ==========================================================
--Début du traitement des données
-- ==========================================================


-- ==========================================================
-- Création d'une vue matérialisée 'mos_foncier_agrege_temp' qui agrège les données foncières par commune et par code,
-- calcule la surface totale des géométries, génère des identifiants uniques, et transforme les géométries dans le système de coordonnées EPSG:2154.

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_temp
TABLESPACE pg_default
AS
 SELECT row_number() OVER () AS id,
    t.nom_commun,
    t.code4_2021,
    t.code4_2011,
    t.codegeo,
    t.dc_mos,
    t.surface_calc_m2,
    t.geom
   FROM ( SELECT mos_foncier.nom_commun,
            mos_foncier.code4_2021,
            mos_foncier.code4_2011,
            mos_foncier.code_insee AS codegeo,
            (((mos_foncier.code_insee::text || '-'::text) || mos_foncier.code4_2011::text) || '-'::text) || mos_foncier.code4_2021::text AS dc_mos,
            st_area(st_transform((st_dump(st_union(mos_foncier.geom))).geom, 2154)) AS surface_calc_m2,
            st_transform((st_dump(st_union(mos_foncier.geom))).geom, 2154) AS geom
           FROM geobretagne.mos_foncier
          GROUP BY mos_foncier.code_insee, mos_foncier.nom_commun, mos_foncier.code4_2021, mos_foncier.code4_2011) t
WITH DATA;

--Création d'un index géographique sur la vue matérialisée
CREATE INDEX idx_mos_foncier_agrege_geom ON visufoncier.mos_foncier_agrege_temp USING gist (geom);
-- ==========================================================

-- ==========================================================
--Création de la table agrege temporaire en transformant les champs code4_2021 et code4_2011 en numérique
CREATE TABLE visufoncier.mos_foncier_agrege_temp AS
SELECT 
    id,
    nom_commun,
    code4_2021::bigint AS code4_2021,
    code4_2011::bigint AS code4_2011,
    codegeo,
    dc_mos,
    surface_calc_m2,
    geom
FROM 
    visufoncier.mos_foncier_agrege;

--Création d'un index géographique sur la table 
CREATE INDEX idx_mos_foncier_agrege_temp_geom ON visufoncier.mos_foncier_agrege_temp USING gist (geom);
-- ==========================================================

-- ==========================================================
--Importation de la nomenclature des codes du MOS dans le schéma visufoncier à partir du .csv
-- ==========================================================

-- ==========================================================
--Création de l'indicateur de consommation et d'artificialisation 2011 - 2021 "conso vs enaf" et "artificialisees vs non artificialisees vs artificialisees en partie"
ALTER TABLE visufoncier.mos_foncier_agrege_temp
ADD COLUMN enaf_conso_2011 text,
ADD COLUMN artificialisees_2011 text;

UPDATE visufoncier.mos_foncier_agrege_temp
SET
    enaf_conso_2011 = nomenclature_mos.enaf_conso,
    artificialisees_2011 = nomenclature_mos.artificialisees
FROM visufoncier.nomenclature_mos
WHERE visufoncier.mos_foncier_agrege_temp.code4_2011 = visufoncier.nomenclature_mos.code_n4;

ALTER TABLE visufoncier.mos_foncier_agrege_temp
ADD COLUMN enaf_conso_2021 text,
ADD COLUMN artificialisees_2021 text;

UPDATE visufoncier.mos_foncier_agrege_temp
SET
    enaf_conso_2021 = nomenclature_mos.enaf_conso,
    artificialisees_2021 = nomenclature_mos.artificialisees
FROM visufoncier.nomenclature_mos
WHERE visufoncier.mos_foncier_agrege_temp.code4_2021 = visufoncier.nomenclature_mos.code_n4;

-- ==========================================================
--Calcul des flux

-- Ajouter deux nouvelles colonnes à la table "mos_foncier_agrege_temp" dans le schéma "visufoncier"
ALTER TABLE visufoncier.mos_foncier_agrege_temp
ADD COLUMN enaf_conso_2021 text,
ADD COLUMN artificialisees_2021 text;

-- Mettre à jour les valeurs des nouvelles colonnes à partir de la table "nomenclature_mos"
UPDATE visufoncier.mos_foncier_agrege_temp
SET
    enaf_conso_2021 = nomenclature_mos.enaf_conso,
    artificialisees_2021 = nomenclature_mos.artificialisees
FROM visufoncier.nomenclature_mos
WHERE visufoncier.mos_foncier_agrege_temp.code4_2021 = visufoncier.nomenclature_mos.code_n4;


-- Ajouter une nouvelle colonne nommée flux_conso dans la table. Si flux_conso=1 alors flux de consommation.
ALTER TABLE visufoncier.mos_foncier_agrege_temp
ADD COLUMN flux_conso integer;

-- Calcul si oui ou non flux en mettant à jour la colonne flux_conso
UPDATE visufoncier.mos_foncier_agrege_temp
SET flux_conso = CASE WHEN enaf_conso_2011 = 'enaf' AND enaf_conso_2021 = 'conso' THEN 1 ELSE 0 END;


-- Ajouter une nouvelle colonne nommée flux_artif dans la table. Si flux_artif=1 alors flux d'artificialisation.
ALTER TABLE visufoncier.mos_foncier_agrege_temp
ADD COLUMN flux_artif integer;

-- Calcul si oui ou non flux en mettant à jour la colonne flux_conso
UPDATE visufoncier.mos_foncier_agrege_temp
SET flux_artif = CASE WHEN artificialisees_2011 = 'non artificialisees' AND (artificialisees_2021 = 'artificialisees' OR artificialisees_2021 = 'artificialisees en partie') THEN 1 ELSE 0 END;


-- Ajouter une nouvelle colonne nommée flux_conso dans la table. Si flux_conso=1 alors flux de consommation.
ALTER TABLE visufoncier.mos_foncier_agrege_temp
ADD COLUMN flux_renaturation integer;

-- Calcul si oui ou non flux en mettant à jour la colonne flux_conso
UPDATE visufoncier.mos_foncier_agrege_temp
SET flux_renaturation = CASE WHEN enaf_conso_2021 = 'enaf' AND enaf_conso_2011 = 'conso' THEN 1 ELSE 0 END;

-- ==========================================================
