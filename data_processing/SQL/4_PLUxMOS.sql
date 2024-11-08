-----------------------------------------------------------------------
--TRAITEMENT DES DONNEES DU GPU VIA MODEL BUILDER QGIS
-----------------------------------------------------------------------

------1. Récupération des données téléchargées ----------------------
--Les données concernant les PLU se récupèrent sur le géoportail de l'urbanisme
https://www.geoportail-urbanisme.gouv.fr/image/Manuel_export_massif.pdf

--Télécharger FileZilla et suivre les étapes de connexion décrites dans le Manuel_export_massif
--/pub/export-wfs/latest/gpkg/wfs_du


--2.Creer la vue matérialisée MOS uniquement sur les ENAF avec un id pour le projet QGIS ou l'on va lancer le modèle ( a adapter pour les prochaines vagues)

DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_enaf_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_enaf_view AS
SELECT 
    ROW_NUMBER() OVER () AS uid,
    codegeo_mos, 
    nom_commune_mos, 
    code4_2021, 
    code4_2011, 
    nature_2021, 
    nature_det_2021, 
    nature_2011, 
    nature_det_2011, 
    surface_calc_m2, 
    surface_calc_ha, 
    enaf_conso_2021, 
    enaf_conso_2011, 
    artificialisees_2021, 
    artificialisees_2011, 
    flux_conso, 
    flux_artif, 
    flux_renaturation, 
    insee_com, 
    nom_commune, 
    siren_epci, 
    insee_dep, 
    insee_reg, 
    nom_epci, 
    nom_scot, 
    fid, 
    nom_departement, 
    millesime_debut, 
    millesime_fin,
    geom
FROM 
    visufoncier.mos_foncier_agrege
WHERE 
    enaf_conso_2021 = 'enaf';

COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_enaf_view IS 'Vue matérialisée qui filtre les données du MOS foncier agrégé pour les ENAF en 2021, afin de permettre l''analyse croisée des indicateurs PLU, PLUI, et CC. Cette vue est utilisée dans le projet QGIS pour le lancement du modèle plu_mos, en se concentrant sur les données spécifiques aux zones et types d''environnement pertinents pour l''analyse du PLU.';

--3.PASSER SUR QGIS / Lancer le modèle mos_plu_2 sur QGIS
--Deux tables sont en sortie du modèle : gpu_mos_enaf_cc et gpu_mos_enaf_plu_plui
--Les données sont pretes à etre exploitées


--4. Création de la seconde analyse ajustée sur les plu/plui

--PARTIE PLU/PLUi
--Creer une copie des tables issues du modèle
-- et filtrer sur code4_2021 IN (3251, 1311, 1334, 1423, 2121, 2511, 3251, 3261)

-- Créer un index spatial sur la géométrie de la table gpu_mos_enaf_plu_plui pour améliorer les performances des requêtes spatiales
CREATE INDEX ON visufoncier.gpu_mos_enaf_plu_plui USING GIST (geom);

--Commentaire
COMMENT ON TABLE visufoncier.gpu_mos_enaf_plu_plui IS 'Table importée directement de QGIS, issue du modèle mos_gpu lancé via le model builder pour l''analyse intersectant les données du GPU et le MOS. Comprend les PLU/PLUI';

--Donner des droits aux tables



--Creer un copie de la table que QGIS à importer sous postgresql pour filtrer uniquement certaines catégories d'ENAF. 
CREATE TABLE visufoncier.gpu_mos_enaf_plu_plui_ajust AS
SELECT *
FROM visufoncier.gpu_mos_enaf_plu_plui
WHERE code4_2021 IN ('3251', '1311', '1334', '1423', '2121', '2511', '3251', '3261');  -- Filtrer les enregistrements par codes spécifiques

-- Créer un index spatial sur la géométrie de la table ajustée gpu_mos_enaf_plu_plui_ajust
CREATE INDEX ON visufoncier.gpu_mos_enaf_plu_plui_ajust USING GIST (geom);

--Creer une copie des données bd topo route nommee dans le schéma IGN en filtrant sur la Bretagne afin de les découper sur la Bretagne
--documentation : https://geoservices.ign.fr/documentation/donnees/vecteur/bdtopo
CREATE TABLE visufoncier.gpu_bdtopo_route_nommee AS
SELECT *
FROM ign.bdtopo_route_nommee
WHERE inseecom_g LIKE '35%' OR inseecom_g LIKE '22%' OR inseecom_g LIKE '29%' OR inseecom_g LIKE '56%'  -- Filtrer les enregistrements par inseecom_g
   OR inseecom_d LIKE '35%' OR inseecom_d LIKE '22%' OR inseecom_d LIKE '29%' OR inseecom_d LIKE '56%';  -- Filtrer les enregistrements par inseecom_d

-- Créer un index spatial sur la géométrie de la table gpu_bdtopo_route_nommee pour améliorer les performances des requêtes spatiales
CREATE INDEX ON visufoncier.gpu_bdtopo_route_nommee USING GIST (the_geom);

--Commentaire
COMMENT ON TABLE visufoncier.gpu_bdtopo_route_nommee IS 'Table issue de la BD topo route nommée sur la Bretagne. Créée à partir de la BD topo dernier millésime de la table dans le schéma IGN';

---------Traitement ajusté
-- Mettre à jour la géométrie dans la table ajustée en soustrayant les routes et en conservant uniquement les polygones
UPDATE visufoncier.gpu_mos_enaf_plu_plui_ajust f
SET geom = ST_Multi(ST_CollectionExtract(ST_Difference(f.geom, ST_Buffer(r.the_geom, 2)), 3))  -- Appliquer une différence spatiale en utilisant un tampon de 2 unités sur les géométries de routes
FROM visufoncier.gpu_bdtopo_route_nommee r
WHERE ST_Intersects(f.geom, r.the_geom)  -- Vérifier l'intersection entre les géométries
AND ST_GeometryType(f.geom) IN ('ST_MultiPolygon', 'ST_Polygon');  -- S'assurer que la géométrie est un MultiPolygon ou un Polygon

-- Supprimer les polygones allongés de la table ajustée
DELETE FROM visufoncier.gpu_mos_enaf_plu_plui_ajust
WHERE 
    ST_Area(geom) > 0  -- Vérifie que l'aire de la géométrie est supérieure à zéro
    AND (ST_Perimeter(geom) / sqrt(NULLIF(ST_Area(geom), 0)) > 7)  -- Divise le périmètre par la racine carrée de l'aire, en évitant la division par zéro avec NULLIF
    AND ST_Area(geom) < 1700;  -- Vérifie que l'aire de la géométrie est inférieure à 1700

-- Supprimer les parties de polygones dont l'aire est inférieure à 150m²
DELETE FROM visufoncier.gpu_mos_enaf_plu_plui_ajust
WHERE ST_Area(geom) < 150;

-- Ajouter une colonne pour stocker l'aire découpée des polygones dans la table ajustée
ALTER TABLE visufoncier.gpu_mos_enaf_plu_plui_ajust
ADD COLUMN aire_decoupee_plu numeric;

-- Mettre à jour la nouvelle colonne avec l'aire des géométries existantes
UPDATE visufoncier.gpu_mos_enaf_plu_plui_ajust f
SET aire_decoupee_plu = ST_Area(geom);  -- Calculer l'aire des géométries et l'assigner à la colonne aire_decoupee_plu

--Commentaire
COMMENT ON TABLE visufoncier.gpu_mos_enaf_plu_plui_ajust IS 'Analyse complémentaire sur l''intersection entre MOS et les PLU PLUi. Retire des zones pas vraiment mobilisables. Intersecte avec la BD topo (tampon 2m) pour les routes, retire les polygones en bande et de moins de 150m². Filtre sur les codes 2021 IN (3251, 1311, 1334, 1423, 2121, 2511, 3251, 3261) ENAF au MOS.';


--PARTIE secteur carte communale
--Creer une copie des tables issues du modèle
-- et filtrer sur code4_2021 IN (3251, 1311, 1334, 1423, 2121, 2511, 3251, 3261)

-- Créer un index spatial sur la géométrie de la table gpu_mos_enaf_cc pour améliorer les performances des requêtes spatiales
CREATE INDEX ON visufoncier.gpu_mos_enaf_cc USING GIST (geom);

--Creer un copie de la table que QGIS à importer sous postgresql
CREATE TABLE visufoncier.gpu_mos_enaf_cc_ajust AS
SELECT *
FROM visufoncier.gpu_mos_enaf_cc
WHERE code4_2021 IN ('3251', '1311', '1334', '1423', '2121', '2511', '3251', '3261');  -- Filtrer les enregistrements par codes spécifiques

-- Créer un index spatial sur la géométrie de la table ajustée gpu_mos_enaf_cc_ajust
CREATE INDEX ON visufoncier.gpu_mos_enaf_cc_ajust USING GIST (geom);
--Commentaire
COMMENT ON TABLE visufoncier.gpu_mos_enaf_cc IS 'Table importée directement de QGIS, issue du modèle mos_gpu lancé via le model builder pour l''analyse intersectant les données du GPU et le MOS. Comprend les cartes communales et les PLU/PLUI';

-- Mettre à jour la géométrie dans la table ajustée en soustrayant les routes et en conservant uniquement les polygones
UPDATE visufoncier.gpu_mos_enaf_cc_ajust f
SET geom = ST_Multi(ST_CollectionExtract(ST_Difference(f.geom, ST_Buffer(r.the_geom, 2)), 3))  -- Appliquer une différence spatiale en utilisant un tampon de 2 unités sur les géométries de routes
FROM visufoncier.gpu_bdtopo_route_nommee r
WHERE ST_Intersects(f.geom, r.the_geom)  -- Vérifier l'intersection entre les géométries
AND ST_GeometryType(f.geom) IN ('ST_MultiPolygon', 'ST_Polygon');  -- S'assurer que la géométrie est un MultiPolygon ou un Polygon

-- Supprimer les polygones allongés de la table ajustée
DELETE FROM visufoncier.gpu_mos_enaf_cc_ajust
WHERE 
    ST_Area(geom) > 0  -- Vérifie que l'aire de la géométrie est supérieure à zéro
    AND (ST_Perimeter(geom) / sqrt(NULLIF(ST_Area(geom), 0)) > 7)  -- Divise le périmètre par la racine carrée de l'aire, en évitant la division par zéro avec NULLIF
    AND ST_Area(geom) < 1700;  -- Vérifie que l'aire de la géométrie est inférieure à 1700

-- Supprimer les parties de polygones dont l'aire est inférieure à 150m²
DELETE FROM visufoncier.gpu_mos_enaf_cc_ajust
WHERE ST_Area(geom) < 150;

-- Ajouter une colonne pour stocker l'aire découpée des polygones dans la table ajustée
ALTER TABLE visufoncier.gpu_mos_enaf_cc_ajust
ADD COLUMN aire_decoupee_plu numeric;

-- Mettre à jour la nouvelle colonne avec l'aire des géométries existantes
UPDATE visufoncier.gpu_mos_enaf_cc_ajust f
SET aire_decoupee_plu = ST_Area(geom);  -- Calculer l'aire des géométries et l'assigner à la colonne aire_decoupee_plu

--Commentaire
COMMENT ON TABLE visufoncier.gpu_mos_enaf_cc_ajust IS 'Analyse complémentaire sur l''intersection entre MOS et cartes communales. Retire des zones pas vraiment mobilisables. Intersecte avec la BD topo (tampon 2m) pour les routes, retire les polygones en bande et de moins de 150m². Filtre sur les codes 2021 IN (3251, 1311, 1334, 1423, 2121, 2511, 3251, 3261) ENAF au MOS.';

--Bien mettre à jour la date de mise à jour des données GPU dans l'onglet crédit du tableau de bord 