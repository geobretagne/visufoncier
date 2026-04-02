-----------------------------------------------------------------------
--TRAITEMENT DES DONNEES DU GPU VIA MODEL BUILDER QGIS
-----------------------------------------------------------------------

------1. Récupération des données téléchargées ----------------------
--Les données concernant les PLU se récupèrent sur le géoportail de l'urbanisme
https://www.geoportail-urbanisme.gouv.fr/image/Manuel_export_massif.pdf

--Télécharger FileZilla et suivre les étapes de connexion décrites dans le Manuel_export_massif
--/pub/export-wfs/latest/gpkg/wfs_du


--2.Creer la vue matérialisée MOS uniquement sur les ENAF avec un id pour le projet QGIS ou l'on va lancer le modèle ( a adapter pour les prochaines vagues)
DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_enaf_view CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_enaf_view AS
SELECT 
    ROW_NUMBER() OVER () AS uid,
    g.code_insee_2024 AS insee_com,
    g.nom_commune_2024 AS nom_commune,
    c.siren_epci,
    e.nom_epci,
    c.insee_dep,
    CASE c.insee_dep
        WHEN '22' THEN 'Côtes-d''Armor'
        WHEN '29' THEN 'Finistère'
        WHEN '35' THEN 'Ille-et-Vilaine'
        WHEN '56' THEN 'Morbihan'
    END AS nom_departement,
    g.code4_2024,
    g.regroup_2024 AS nature_2024,
    g.lib4_2024 AS nature_det_2024,
    'enaf' AS enaf_conso_2024,
    g.surface_m2_2024 / 10000.0 AS surface_calc_ha,
    g.geom
FROM visufoncier.mos_foncier_2024 g
LEFT JOIN ign.express_commune c ON g.code_insee_2024 = c.insee_com
LEFT JOIN ign.express_epci e ON c.siren_epci = e.code_epci
WHERE g.type_conso_2024 like 'enaf';

CREATE INDEX idx_v2_enaf_insee ON visufoncier.v2_mos_enaf_view (insee_com);
CREATE INDEX idx_v2_enaf_nature ON visufoncier.v2_mos_enaf_view (nature_2024);
CREATE INDEX idx_v2_enaf_epci ON visufoncier.v2_mos_enaf_view (nom_epci);
CREATE INDEX idx_v2_enaf_geom ON visufoncier.v2_mos_enaf_view USING gist (geom);

COMMENT ON MATERIALIZED VIEW visufoncier.v2_mos_enaf_view IS 
'Vue matérialisée filtrant les données ENAF du MOS 2024 pour analyse croisée PLU/PLUI/CC.';

GRANT SELECT ON visufoncier.v2_mos_enaf_view TO "app-visufoncier";
GRANT ALL ON visufoncier.v2_mos_enaf_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_mos_enaf_view TO "www-data";


--3.PASSER SUR QGIS / Lancer le modèle mos_plu_2 sur QGIS

--Deux tables sont en sortie du modèle : gpu_mos_enaf_cc et gpu_mos_enaf_plu_plui !! changer de nom de sortie SQL sur le model pour ne pas écraser l'ancienne donnée
--Les données sont pretes à etre exploitées

--L'analyse est à relancer sur tous les millésimes si correction des anciens polygone (si nouveau enaf)


--4. Création de la seconde analyse ajustée sur les plu/plui

--PARTIE PLU/PLUi
--Creer une copie des tables issues du modèle
-- et filtrer sur code4_2024 IN (3251, 1311, 1334, 1423, 2121, 2511, 3251, 3261)
-- Créer un index spatial sur la géométrie de la table v2_gpu_mos_enaf_plu_plui pour améliorer les performances des requêtes spatiales
CREATE INDEX ON visufoncier.v2_gpu_mos_enaf_plu_plui USING GIST (geom);

--Commentaire
COMMENT ON TABLE visufoncier.v2_gpu_mos_enaf_plu_plui IS 'Table importée directement de QGIS, issue du modèle mos_gpu lancé via le model builder pour l''analyse intersectant les données du GPU et le MOS. Comprend les PLU/PLUI';

--Donner des droits aux tables
   
   GRANT SELECT ON visufoncier.v2_gpu_mos_enaf_cc TO "app-visufoncier";
GRANT ALL PRIVILEGES ON visufoncier.v2_gpu_mos_enaf_cc TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_gpu_mos_enaf_cc TO "www-data";


   GRANT SELECT ON visufoncier.v2_gpu_mos_enaf_plu_plui TO "app-visufoncier";
GRANT ALL PRIVILEGES ON visufoncier.v2_gpu_mos_enaf_plu_plui TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_gpu_mos_enaf_plu_plui TO "www-data";




--Analyse ajustée 
CREATE TABLE visufoncier.v2_gpu_mos_enaf_plu_plui_ajust AS
SELECT *
FROM visufoncier.v2_gpu_mos_enaf_plu_plui
WHERE code4_2024 IN ('3251', '1311', '1334', '1423', '2121', '2511', '3251', '3261'); 

CREATE INDEX ON visufoncier.v2_gpu_mos_enaf_plu_plui_ajust USING GIST (geom);

GRANT SELECT ON visufoncier.v2_gpu_mos_enaf_plu_plui_ajust TO "app-visufoncier";
GRANT ALL PRIVILEGES ON visufoncier.v2_gpu_mos_enaf_plu_plui_ajust TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_gpu_mos_enaf_plu_plui_ajust TO "www-data";


CREATE TABLE visufoncier.v2_gpu_bdtopo_route_nommee AS
SELECT *
FROM ign.bdtopo_route_nommee
WHERE inseecom_g LIKE '35%' OR inseecom_g LIKE '22%' OR inseecom_g LIKE '29%' OR inseecom_g LIKE '56%'  -- Filtrer les enregistrements par inseecom_g
   OR inseecom_d LIKE '35%' OR inseecom_d LIKE '22%' OR inseecom_d LIKE '29%' OR inseecom_d LIKE '56%';  -- Filtrer les enregistrements par inseecom_d

 -- Créer un index spatial sur la géométrie de la table gpu_bdtopo_route_nommee pour améliorer les performances des requêtes spatiales
CREATE INDEX ON visufoncier.v2_gpu_bdtopo_route_nommee USING GIST (the_geom);

--Commentaire
COMMENT ON TABLE visufoncier.v2_gpu_bdtopo_route_nommee IS 'Table issue de la BD topo route nommée sur la Bretagne. Créée à partir de la BD topo dernier millésime de la table dans le schéma IGN';



---------Traitement ajusté
-- Mettre à jour la géométrie dans la table ajustée en soustrayant les routes et en conservant uniquement les polygones
UPDATE visufoncier.v2_gpu_mos_enaf_plu_plui_ajust f
SET geom = ST_Multi(ST_CollectionExtract(ST_Difference(f.geom, ST_Buffer(r.the_geom, 2)), 3))  -- Appliquer une différence spatiale en utilisant un tampon de 2 unités sur les géométries de routes
FROM visufoncier.gpu_bdtopo_route_nommee r
WHERE ST_Intersects(f.geom, r.the_geom)  -- Vérifier l'intersection entre les géométries
AND ST_GeometryType(f.geom) IN ('ST_MultiPolygon', 'ST_Polygon');  -- S'assurer que la géométrie est un MultiPolygon ou un Polygon

-- Supprimer les polygones allongés de la table ajustée
DELETE FROM visufoncier.v2_gpu_mos_enaf_plu_plui_ajust
WHERE 
    ST_Area(geom) > 0  -- Vérifie que l'aire de la géométrie est supérieure à zéro
    AND (ST_Perimeter(geom) / sqrt(NULLIF(ST_Area(geom), 0)) > 7)  -- Divise le périmètre par la racine carrée de l'aire, en évitant la division par zéro avec NULLIF
    AND ST_Area(geom) < 1700;  -- Vérifie que l'aire de la géométrie est inférieure à 1700

-- Supprimer les parties de polygones dont l'aire est inférieure à 150m²
DELETE FROM visufoncier.v2_gpu_mos_enaf_plu_plui_ajust
WHERE ST_Area(geom) < 150;

-- Ajouter une colonne pour stocker l'aire découpée des polygones dans la table ajustée
ALTER TABLE visufoncier.v2_gpu_mos_enaf_plu_plui_ajust
ADD COLUMN aire_decoupee_plu numeric;

-- Mettre à jour la nouvelle colonne avec l'aire des géométries existantes
UPDATE visufoncier.v2_gpu_mos_enaf_plu_plui_ajust f
SET aire_decoupee_plu = ST_Area(geom);  -- Calculer l'aire des géométries et l'assigner à la colonne aire_decoupee_plu

--Commentaire
COMMENT ON TABLE visufoncier.v2_gpu_mos_enaf_plu_plui_ajust IS 'Analyse complémentaire sur l''intersection entre MOS et les PLU PLUi. Retire des zones pas vraiment mobilisables. Intersecte avec la BD topo (tampon 2m) pour les routes, retire les polygones en bande et de moins de 150m². Filtre sur les codes 2021 IN (3251, 1311, 1334, 1423, 2121, 2511, 3251, 3261) ENAF au MOS.';


--PARTIE secteur carte communale
--Creer une copie des tables issues du modèle
-- et filtrer sur code4_2024 IN (3251, 1311, 1334, 1423, 2121, 2511, 3251, 3261)



--Creer un copie de la table que QGIS à importer sous postgresql
CREATE TABLE visufoncier.v2_gpu_mos_enaf_cc_ajust AS
SELECT *
FROM visufoncier.v2_gpu_mos_enaf_cc
WHERE code4_2024 IN ('3251', '1311', '1334', '1423', '2121', '2511', '3251', '3261');  -- Filtrer les enregistrements par codes spécifiques


   GRANT SELECT ON visufoncier.v2_gpu_mos_enaf_cc_ajust TO "app-visufoncier";
GRANT ALL PRIVILEGES ON visufoncier.v2_gpu_mos_enaf_cc_ajust TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_gpu_mos_enaf_cc_ajust TO "www-data";

-- Créer un index spatial sur la géométrie de la table v2_gpu_mos_enaf_cc pour améliorer les performances des requêtes spatiales
CREATE INDEX ON visufoncier.v2_gpu_mos_enaf_cc USING GIST (geom);

--Commentaire
COMMENT ON TABLE visufoncier.v2_gpu_mos_enaf_cc IS 'Table importée directement de QGIS, issue du modèle mos_gpu lancé via le model builder pour l''analyse intersectant les données du GPU et le MOS. Comprend les cartes communales et les PLU/PLUI';

-- Mettre à jour la géométrie dans la table ajustée en soustrayant les routes et en conservant uniquement les polygones
UPDATE visufoncier.v2_gpu_mos_enaf_cc_ajust f
SET geom = ST_Multi(ST_CollectionExtract(ST_Difference(f.geom, ST_Buffer(r.the_geom, 2)), 3))  -- Appliquer une différence spatiale en utilisant un tampon de 2 unités sur les géométries de routes
FROM visufoncier.gpu_bdtopo_route_nommee r
WHERE ST_Intersects(f.geom, r.the_geom)  -- Vérifier l'intersection entre les géométries
AND ST_GeometryType(f.geom) IN ('ST_MultiPolygon', 'ST_Polygon');  -- S'assurer que la géométrie est un MultiPolygon ou un Polygon

-- Supprimer les polygones allongés de la table ajustée
DELETE FROM visufoncier.v2_gpu_mos_enaf_cc_ajust
WHERE 
    ST_Area(geom) > 0  -- Vérifie que l'aire de la géométrie est supérieure à zéro
    AND (ST_Perimeter(geom) / sqrt(NULLIF(ST_Area(geom), 0)) > 7)  -- Divise le périmètre par la racine carrée de l'aire, en évitant la division par zéro avec NULLIF
    AND ST_Area(geom) < 1700;  -- Vérifie que l'aire de la géométrie est inférieure à 1700

-- Supprimer les parties de polygones dont l'aire est inférieure à 150m²
DELETE FROM visufoncier.v2_gpu_mos_enaf_cc_ajust
WHERE ST_Area(geom) < 150;

-- Ajouter une colonne pour stocker l'aire découpée des polygones dans la table ajustée
ALTER TABLE visufoncier.v2_gpu_mos_enaf_cc_ajust
ADD COLUMN aire_decoupee_plu numeric;

-- Mettre à jour la nouvelle colonne avec l'aire des géométries existantes
UPDATE visufoncier.v2_gpu_mos_enaf_cc_ajust f
SET aire_decoupee_plu = ST_Area(geom);  -- Calculer l'aire des géométries et l'assigner à la colonne aire_decoupee_plu

--Commentaire
COMMENT ON TABLE visufoncier.v2_gpu_mos_enaf_cc_ajust IS 'Analyse complémentaire sur l''intersection entre MOS et cartes communales. Retire des zones pas vraiment mobilisables. Intersecte avec la BD topo (tampon 2m) pour les routes, retire les polygones en bande et de moins de 150m². Filtre sur les codes 2021 IN (3251, 1311, 1334, 1423, 2121, 2511, 3251, 3261) ENAF au MOS.';

--Bien mettre à jour la date de mise à jour des données GPU dans l'onglet crédit du tableau de bord 

--ne pas oublier les scot


-- Ajouter les colonnes manquantes pour filtre (SCOT)
ALTER TABLE visufoncier.v2_gpu_mos_enaf_cc 
ADD COLUMN IF NOT EXISTS nom_scot VARCHAR

UPDATE visufoncier.v2_gpu_mos_enaf_cc t
SET nom_scot = ff.scot
FROM visufoncier.ff_obs_artif_conso_com_2009_2024 ff
WHERE t.insee_com = ff.idcom;

-- Ajouter les colonnes manquantes
ALTER TABLE visufoncier.v2_gpu_mos_enaf_cc_ajust
ADD COLUMN IF NOT EXISTS nom_scot VARCHAR

UPDATE visufoncier.v2_gpu_mos_enaf_cc_ajust t
SET nom_scot = ff.scot
FROM visufoncier.ff_obs_artif_conso_com_2009_2024 ff
WHERE t.insee_com = ff.idcom;


-- Ajouter les colonnes manquantes
ALTER TABLE visufoncier.v2_gpu_mos_enaf_plu_plui 
ADD COLUMN IF NOT EXISTS nom_scot VARCHAR

UPDATE visufoncier.v2_gpu_mos_enaf_plu_plui t
SET nom_scot = ff.scot
FROM visufoncier.ff_obs_artif_conso_com_2009_2024 ff
WHERE t.insee_com = ff.idcom;

-- Ajouter les colonnes manquantes
ALTER TABLE visufoncier.v2_gpu_mos_enaf_plu_plui_ajust
ADD COLUMN IF NOT EXISTS nom_scot VARCHAR

UPDATE visufoncier.v2_gpu_mos_enaf_plu_plui_ajust t
SET nom_scot = ff.scot
FROM visufoncier.ff_obs_artif_conso_com_2009_2024 ff
WHERE t.insee_com = ff.idcom;