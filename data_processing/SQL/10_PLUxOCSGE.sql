-------------------
--Intersection des données du GPU et de l'OCS GETBND
------------------

--syntaxe en developpement 

--Creer la vue matérialisée pour extraire uniquement les parcelles non artificialisées en 2021
--ajouter la vue à QGIS

DROP MATERIALIZED VIEW IF EXISTS visufoncier.ocsge_non_artif_view;

CREATE MATERIALIZED VIEW visufoncier.ocsge_non_artif_view AS
SELECT 
    ROW_NUMBER() OVER () AS uid,
    *
FROM (
    SELECT *
    FROM visufoncier.ocsge_22_2021_brut
    WHERE artif = 'non artif'
    
    UNION ALL
    
    SELECT *
    FROM visufoncier.ocsge_29_2021_brut
    WHERE artif = 'non artif'
    
    UNION ALL
    
    SELECT *
    FROM visufoncier.ocsge_35_2020_brut
    WHERE artif = 'non artif'
) AS combined_data;

-- Crée un index unique sur la colonne uid
CREATE UNIQUE INDEX ON visufoncier.ocsge_non_artif_view(uid);

COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_non_artif_view IS 'Vue matérialisée pour l''analyse intersectant les données du GPU et l''OCSGE NG. Cette vue est à ajouter sur le projet QGIS pour le lancement du modèle plu_ocsge.';

--ajout des droits sur la vue

--Se rendre sur QGIS pour lancer le modèle. pour le moment, le modèle ne fonctionne pas à cause de problème de géométrie sur des polygones: voir pour ajouter des algo de correction. 