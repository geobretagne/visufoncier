
--------------------------------------------------------------------------------
--Creation des vues matérialisées reliées au tableau de bord superset Visufoncier
--------------------------------------------------------------------------------

--Rafraichir seulement les vues si modificiationn des tables de base, sinon relancer les vues 


--La syntaxe ci dessous créer les vues pour l'analyse sur 3 départements x 2 millésimes : 35 (2017-2020), 22 et 29 (2018-2021) --A adapter

--creer la vue ppur stock couverture
DROP MATERIALIZED VIEW IF EXISTS visufoncier.ocsge_code_cs_lib_view;

CREATE MATERIALIZED VIEW visufoncier.ocsge_code_cs_lib_view AS
SELECT
    t2.insee_com AS insee_com, -- Prendre uniquement le code INSEE de la période de fin
    t2.nom_commune AS nom_commune, -- Variables de filtre uniquement de la période de fin
    t2.nom_epci AS nom_epci,
    t2.nom_scot AS nom_scot,
    t2.nom_departement AS nom_departement,
    t1.millesime_debut AS millesime_debut, -- Millésime de début
    t2.millesime_fin AS millesime_fin, -- Millésime de fin
    t1.code_cs_lib AS code_cs_lib_debut, -- Code CS de début
    t2.code_cs_lib AS code_cs_lib_fin, -- Code CS de fin
    t1.cs_regroup1 AS cs_regroup1_debut, 
    t2.cs_regroup1 AS cs_regroup1_fin, 
    t1.cs_regroup2 AS cs_regroup2_debut, 
    t2.cs_regroup2 AS cs_regroup2_fin, 
    t1.cs_regroup3 AS cs_regroup3_debut, 
    t2.cs_regroup3 AS cs_regroup3_fin, 
    t1.surface_ha AS surface_ha_debut, -- Surface de début
    t2.surface_ha AS surface_ha_fin -- Surface de fin
FROM
    (
        -- Table pour les périodes de début
        SELECT '2018' AS millesime_debut, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2018', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha)
        FROM visufoncier.ocsge_29_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2017', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha)
        FROM visufoncier.ocsge_35_2017_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
    ) t1
INNER JOIN
    (
        -- Table pour les périodes de fin
        SELECT '2021' AS millesime_fin, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2021', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib, cs_regroup1, cs_regroup2, cs_regroup3,SUM(surface_ha)
        FROM visufoncier.ocsge_29_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2020', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib, cs_regroup1, cs_regroup2, cs_regroup3,SUM(surface_ha)
        FROM visufoncier.ocsge_35_2020_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
    ) t2
ON t1.insee_com = t2.insee_com AND t1.code_cs_lib = t2.code_cs_lib AND t1.nom_departement = t2.nom_departement;

COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_code_cs_lib_view IS 'Vue matérialisée pour l''analyse des catégories de couvertures du sol.';



--creer la vue pour les catégories en stock Usage
DROP MATERIALIZED VIEW IF EXISTS visufoncier.ocsge_code_us_lib_view;

CREATE MATERIALIZED VIEW visufoncier.ocsge_code_us_lib_view AS
SELECT
    t2.insee_com AS insee_com, -- Prendre uniquement le code INSEE de la période de fin
    t2.nom_commune AS nom_commune, -- Variables de filtre uniquement de la période de fin
    t2.nom_epci AS nom_epci,
    t2.nom_scot AS nom_scot,
    t2.nom_departement AS nom_departement,
    t1.millesime_debut AS millesime_debut, -- Millésime de début
    t2.millesime_fin AS millesime_fin, -- Millésime de fin
    t1.code_us_lib AS code_us_lib_debut, -- Code US de début
    t2.code_us_lib AS code_us_lib_fin, -- Code US de fin
    t1.us_regroup1 AS us_regroup1_debut, 
    t2.us_regroup1 AS us_regroup1_fin, 
    t1.surface_ha AS surface_ha_debut, -- Surface de début
    t2.surface_ha AS surface_ha_fin -- Surface de fin
FROM
    (
        -- Table pour les périodes de début
        SELECT '2018' AS millesime_debut, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2018', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib, us_regroup1,SUM(surface_ha)
        FROM visufoncier.ocsge_29_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2017', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib, us_regroup1,SUM(surface_ha)
        FROM visufoncier.ocsge_35_2017_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
    ) t1
INNER JOIN
    (
        -- Table pour les périodes de fin
        SELECT '2021' AS millesime_fin, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib, us_regroup1,SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2021', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1, SUM(surface_ha)
        FROM visufoncier.ocsge_29_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2020', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1, SUM(surface_ha)
        FROM visufoncier.ocsge_35_2020_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
    ) t2
ON t1.insee_com = t2.insee_com AND t1.code_us_lib = t2.code_us_lib AND t1.nom_departement = t2.nom_departement;

COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_code_us_lib_view IS 'Vue matérialisée pour l''analyse des catégories d''usage du sol.';


   
DROP MATERIALIZED VIEW IF EXISTS visufoncier.ocsge_code_cs_lib_artif_view;

CREATE MATERIALIZED VIEW visufoncier.ocsge_code_cs_lib_artif_view AS
SELECT
    t2.insee_com AS insee_com, -- Prendre uniquement le code INSEE de la période de fin
    t2.nom_commune AS nom_commune, -- Variables de filtre uniquement de la période de fin
    t2.nom_epci AS nom_epci,
    t2.nom_scot AS nom_scot,
    t2.nom_departement AS nom_departement,
    t1.millesime_debut AS millesime_debut, -- Millésime de début
    t2.millesime_fin AS millesime_fin, -- Millésime de fin
    t1.code_cs_lib AS code_cs_lib_debut, -- Code CS de début
    t2.code_cs_lib AS code_cs_lib_fin, -- Code CS de fin
    t1.cs_regroup1 AS cs_regroup1_debut, 
    t2.cs_regroup1 AS cs_regroup1_fin, 
    t1.cs_regroup2 AS cs_regroup2_debut, 
    t2.cs_regroup2 AS cs_regroup2_fin, 
    t1.cs_regroup3 AS cs_regroup3_debut, 
    t2.cs_regroup3 AS cs_regroup3_fin, 
    t1.surface_ha AS surface_ha_debut, -- Surface de début
    t2.surface_ha AS surface_ha_fin -- Surface de fin
FROM
    (
        -- Table pour les périodes de début
        SELECT '2018' AS millesime_debut, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> '' and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2018', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha)
        FROM visufoncier.ocsge_29_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2017', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha)
        FROM visufoncier.ocsge_35_2017_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
    ) t1
INNER JOIN
    (
        -- Table pour les périodes de fin
        SELECT '2021' AS millesime_fin, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2021', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib, cs_regroup1, cs_regroup2, cs_regroup3,SUM(surface_ha)
        FROM visufoncier.ocsge_29_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2020', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib, cs_regroup1, cs_regroup2, cs_regroup3,SUM(surface_ha)
        FROM visufoncier.ocsge_35_2020_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
    ) t2
ON t1.insee_com = t2.insee_com AND t1.code_cs_lib = t2.code_cs_lib AND t1.nom_departement = t2.nom_departement;


COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_code_cs_lib_artif_view IS 'Vue matérialisée qui agrège les données sur les surfaces artificialisées (artif) par commune, en utilisant les codes CS pour les périodes de début (2017-2018) et de fin (2020-2021). Elle regroupe les surfaces en fonction des codes CS, des regroupements, et des départements. Cette vue permet de comparer les évolutions des surfaces sur la période étudiée pour chaque commune et chaque code CS, en distinguant les données de début et de fin. Elle est utile pour l''analyse des changements dans les surfaces artificialisées sur les différentes années.';


DROP MATERIALIZED VIEW IF EXISTS visufoncier.ocsge_code_cs_lib_nonartif_view;

CREATE MATERIALIZED VIEW visufoncier.ocsge_code_cs_lib_nonartif_view AS
SELECT
    t2.insee_com AS insee_com, -- Prendre uniquement le code INSEE de la période de fin
    t2.nom_commune AS nom_commune, -- Variables de filtre uniquement de la période de fin
    t2.nom_epci AS nom_epci,
    t2.nom_scot AS nom_scot,
    t2.nom_departement AS nom_departement,
    t1.millesime_debut AS millesime_debut, -- Millésime de début
    t2.millesime_fin AS millesime_fin, -- Millésime de fin
    t1.code_cs_lib AS code_cs_lib_debut, -- Code CS de début
    t2.code_cs_lib AS code_cs_lib_fin, -- Code CS de fin
    t1.cs_regroup1 AS cs_regroup1_debut, 
    t2.cs_regroup1 AS cs_regroup1_fin, 
    t1.cs_regroup2 AS cs_regroup2_debut, 
    t2.cs_regroup2 AS cs_regroup2_fin, 
    t1.cs_regroup3 AS cs_regroup3_debut, 
    t2.cs_regroup3 AS cs_regroup3_fin, 
    t1.surface_ha AS surface_ha_debut, -- Surface de début
    t2.surface_ha AS surface_ha_fin -- Surface de fin
FROM
    (
        -- Table pour les périodes de début
        SELECT '2018' AS millesime_debut, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> '' and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2018', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha)
        FROM visufoncier.ocsge_29_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2017', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha)
        FROM visufoncier.ocsge_35_2017_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
    ) t1
INNER JOIN
    (
        -- Table pour les périodes de fin
        SELECT '2021' AS millesime_fin, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib,cs_regroup1, cs_regroup2, cs_regroup3, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2021', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib, cs_regroup1, cs_regroup2, cs_regroup3,SUM(surface_ha)
        FROM visufoncier.ocsge_29_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
        
        UNION
        
        SELECT '2020', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_cs_lib, cs_regroup1, cs_regroup2, cs_regroup3,SUM(surface_ha)
        FROM visufoncier.ocsge_35_2020_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_cs_lib, nom_departement,cs_regroup1, cs_regroup2, cs_regroup3
    ) t2
ON t1.insee_com = t2.insee_com AND t1.code_cs_lib = t2.code_cs_lib AND t1.nom_departement = t2.nom_departement;

COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_code_cs_lib_nonartif_view IS 'Vue matérialisée qui agrège les données sur les surfaces non artificialisées (non artif) par commune, en utilisant les codes CS pour les périodes de début (2017-2018) et de fin (2020-2021). Elle regroupe les surfaces en fonction des codes CS, des regroupements, et des départements. Cette vue permet de comparer les évolutions des surfaces non artificialisées sur la période étudiée pour chaque commune et chaque code CS, en distinguant les données de début et de fin. Elle est utile pour l''analyse des changements dans les surfaces non artificialisées sur les différentes années.';



DROP MATERIALIZED VIEW IF EXISTS visufoncier.ocsge_code_us_lib_artif_view;

CREATE MATERIALIZED VIEW visufoncier.ocsge_code_us_lib_artif_view AS
SELECT
    t2.insee_com AS insee_com, -- Prendre uniquement le code INSEE de la période de fin
    t2.nom_commune AS nom_commune, -- Variables de filtre uniquement de la période de fin
    t2.nom_epci AS nom_epci,
    t2.nom_scot AS nom_scot,
    t2.nom_departement AS nom_departement,
    t1.millesime_debut AS millesime_debut, -- Millésime de début
    t2.millesime_fin AS millesime_fin, -- Millésime de fin
    t1.code_us_lib AS code_us_lib_debut, -- Code us de début
    t2.code_us_lib AS code_us_lib_fin, -- Code us de fin
    t1.us_regroup1 AS us_regroup1_debut, 
    t2.us_regroup1 AS us_regroup1_fin, 
    t1.surface_ha AS surface_ha_debut, -- Surface de début
    t2.surface_ha AS surface_ha_fin -- Surface de fin
FROM
    (
        -- Table pour les périodes de début
        SELECT '2018' AS millesime_debut, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> '' and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2018', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1,SUM(surface_ha)
        FROM visufoncier.ocsge_29_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2017', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1, SUM(surface_ha)
        FROM visufoncier.ocsge_35_2017_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
    ) t1
INNER JOIN
    (
        -- Table pour les périodes de fin
        SELECT '2021' AS millesime_fin, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2021', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib, us_regroup1,SUM(surface_ha)
        FROM visufoncier.ocsge_29_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2020', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib, us_regroup1,SUM(surface_ha)
        FROM visufoncier.ocsge_35_2020_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
    ) t2
ON t1.insee_com = t2.insee_com AND t1.code_us_lib = t2.code_us_lib AND t1.nom_departement = t2.nom_departement;

COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_code_us_lib_artif_view IS 'Vue matérialisée pour l''analyse des catégories d''usages filtrée sur artif.';



DROP MATERIALIZED VIEW IF EXISTS visufoncier.ocsge_code_us_lib_nonartif_view;

CREATE MATERIALIZED VIEW visufoncier.ocsge_code_us_lib_nonartif_view AS
SELECT
    t2.insee_com AS insee_com, -- Prendre uniquement le code INSEE de la période de fin
    t2.nom_commune AS nom_commune, -- Variables de filtre uniquement de la période de fin
    t2.nom_epci AS nom_epci,
    t2.nom_scot AS nom_scot,
    t2.nom_departement AS nom_departement,
    t1.millesime_debut AS millesime_debut, -- Millésime de début
    t2.millesime_fin AS millesime_fin, -- Millésime de fin
    t1.code_us_lib AS code_us_lib_debut, -- Code us de début
    t2.code_us_lib AS code_us_lib_fin, -- Code us de fin
    t1.us_regroup1 AS us_regroup1_debut, 
    t2.us_regroup1 AS us_regroup1_fin, 
    t1.surface_ha AS surface_ha_debut, -- Surface de début
    t2.surface_ha AS surface_ha_fin -- Surface de fin
FROM
    (
        -- Table pour les périodes de début
        SELECT '2018' AS millesime_debut, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> '' and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2018', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1, SUM(surface_ha)
        FROM visufoncier.ocsge_29_2018_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2017', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1, SUM(surface_ha)
        FROM visufoncier.ocsge_35_2017_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
    ) t1
INNER JOIN
    (
        -- Table pour les périodes de fin
        SELECT '2021' AS millesime_fin, insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib,us_regroup1, SUM(surface_ha) AS surface_ha
        FROM visufoncier.ocsge_22_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2021', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib, us_regroup1,SUM(surface_ha)
        FROM visufoncier.ocsge_29_2021_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
        
        UNION
        
        SELECT '2020', insee_com, nom_commune, nom_epci, nom_scot, nom_departement, code_us_lib, us_regroup1,SUM(surface_ha)
        FROM visufoncier.ocsge_35_2020_brut
        WHERE insee_com IS NOT NULL AND insee_com <> ''and artif='non artif'
        GROUP BY insee_com, nom_commune, nom_epci, nom_scot, code_us_lib, nom_departement,us_regroup1
    ) t2
ON t1.insee_com = t2.insee_com AND t1.code_us_lib = t2.code_us_lib AND t1.nom_departement = t2.nom_departement;

COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_code_us_lib_nonartif_view IS 'Vue matérialisée qui agrège les données sur les surfaces non artificialisées (non artif) par commune, en utilisant les codes US pour les périodes de début (2017-2018) et de fin (2020-2021). Elle regroupe les surfaces en fonction des codes US, des regroupements, et des départements. Cette vue permet de comparer les évolutions des surfaces non artificialisées sur la période étudiée pour chaque commune et chaque code US, en distinguant les données de début et de fin. Elle est utile pour l''analyse des changements dans les surfaces non artificialisées sur les différentes années.';


--Vue matérialisée une ligne par commune, regroupant tous les départements
CREATE MATERIALIZED VIEW visufoncier.ocsge_brut_agrege_com AS
SELECT
    b.insee_com,
    b.nom_commune,
    b.nom_epci,
    b.nom_scot,
    b.nom_departement,
    MIN(b.millesime_debut) AS millesime_debut,
    MAX(b.millesime_fin) AS millesime_fin,
    ign.geom AS geom  -- Récupère la géométrie depuis la table IGN
FROM (
    -- Department 35
    SELECT insee_com, nom_commune, nom_epci, nom_scot, nom_departement, millesime_debut, millesime_fin
    FROM visufoncier.ocsge_35_2020_brut
    -- Department 22
    UNION ALL
    SELECT insee_com, nom_commune, nom_epci, nom_scot, nom_departement, millesime_debut, millesime_fin
    FROM visufoncier.ocsge_22_2021_brut
    -- Department 29
    UNION ALL
    SELECT insee_com, nom_commune, nom_epci, nom_scot, nom_departement, millesime_debut, millesime_fin
    FROM visufoncier.ocsge_29_2021_brut
) b
JOIN ign.express_commune ign
ON b.insee_com = ign.insee_com  -- Jointure avec la table IGN pour récupérer la géométrie
GROUP BY
    b.insee_com, b.nom_commune, b.nom_epci, b.nom_scot, b.nom_departement, ign.geom;
   
   
COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_brut_agrege_com IS 'Vue matérialisée agrégée par commune, regroupant les données des départements 35, 22 et 29. Cette vue récupère les informations sur les communes (insee_com, nom_commune, etc.) et agrège les périodes de millésimes pour chaque commune. Elle joint également les données avec la table IGN pour récupérer la géométrie des communes, permettant ainsi de lier les données géographiques et temporelles dans le tableau de bord Superset Visufoncier.';



--Vue pour gérer les différents filtres de l'ocsge dans superset
CREATE MATERIALIZED VIEW visufoncier.ocsge_agrege_com_liengeo_view
TABLESPACE pg_default
AS 
WITH aggregated_geom AS (
    -- Agrégation par commune
    SELECT 
        ocsge_brut_agrege_com.insee_com,
        ocsge_brut_agrege_com.nom_commune,
        ocsge_brut_agrege_com.nom_epci,
        ocsge_brut_agrege_com.nom_scot,
        'Communes'::text AS type_territoire,
        ocsge_brut_agrege_com.nom_commune AS territoire,
        ocsge_brut_agrege_com.nom_departement,
        ST_Centroid(ocsge_brut_agrege_com.geom) AS centroid_geom,
        14 AS z,
        ocsge_brut_agrege_com.millesime_debut,
        ocsge_brut_agrege_com.millesime_fin,
        date_part('year'::text, ocsge_brut_agrege_com.millesime_debut) AS annee_debut,
        date_part('year'::text, ocsge_brut_agrege_com.millesime_fin) AS annee_fin
    FROM visufoncier.ocsge_brut_agrege_com
    UNION ALL
    -- Agrégation par département
    SELECT 
        NULL::character varying AS insee_com,
        NULL::character varying AS nom_commune,
        NULL::character varying AS nom_epci,
        NULL::character varying AS nom_scot,
        'Département'::text AS type_territoire,
        ocsge_brut_agrege_com.nom_departement AS territoire,
        ocsge_brut_agrege_com.nom_departement,
        ST_Centroid(ST_Collect(ocsge_brut_agrege_com.geom)) AS centroid_geom,
        12 AS z,
        MIN(ocsge_brut_agrege_com.millesime_debut) AS millesime_debut,
        MAX(ocsge_brut_agrege_com.millesime_fin) AS millesime_fin,
        date_part('year'::text, MIN(ocsge_brut_agrege_com.millesime_debut)) AS annee_debut,
        date_part('year'::text, MAX(ocsge_brut_agrege_com.millesime_fin)) AS annee_fin
    FROM visufoncier.ocsge_brut_agrege_com
    WHERE "left"(ocsge_brut_agrege_com.insee_com::text, 2) = ANY (ARRAY['35'::text, '22'::text, '29'::text])
    GROUP BY ocsge_brut_agrege_com.nom_departement
    UNION ALL
    -- Agrégation par EPCI
    SELECT 
        NULL::character varying AS insee_com,
        NULL::character varying AS nom_commune,
        ocsge_brut_agrege_com.nom_epci,
        ocsge_brut_agrege_com.nom_scot,
        'EPCI'::text AS type_territoire,
        ocsge_brut_agrege_com.nom_epci AS territoire,
        ocsge_brut_agrege_com.nom_departement,
        ST_Centroid(ST_Collect(ocsge_brut_agrege_com.geom)) AS centroid_geom,
        11 AS z,
        MIN(ocsge_brut_agrege_com.millesime_debut) AS millesime_debut,
        MAX(ocsge_brut_agrege_com.millesime_fin) AS millesime_fin,
        date_part('year'::text, MIN(ocsge_brut_agrege_com.millesime_debut)) AS annee_debut,
        date_part('year'::text, MAX(ocsge_brut_agrege_com.millesime_fin)) AS annee_fin
    FROM visufoncier.ocsge_brut_agrege_com
    GROUP BY ocsge_brut_agrege_com.nom_epci, ocsge_brut_agrege_com.nom_scot, ocsge_brut_agrege_com.nom_departement
    UNION ALL
    -- Agrégation par SCOT
    SELECT 
        NULL::character varying AS insee_com,
        NULL::character varying AS nom_commune,
        NULL::character varying AS nom_epci,
        ocsge_brut_agrege_com.nom_scot,
        'SCOT'::text AS type_territoire,
        ocsge_brut_agrege_com.nom_scot AS territoire,
        ocsge_brut_agrege_com.nom_departement,
        ST_Centroid(ST_Collect(ocsge_brut_agrege_com.geom)) AS centroid_geom,
        11 AS z,
        MIN(ocsge_brut_agrege_com.millesime_debut) AS millesime_debut,
        MAX(ocsge_brut_agrege_com.millesime_fin) AS millesime_fin,
        date_part('year'::text, MIN(ocsge_brut_agrege_com.millesime_debut)) AS annee_debut,
        date_part('year'::text, MAX(ocsge_brut_agrege_com.millesime_fin)) AS annee_fin
    FROM visufoncier.ocsge_brut_agrege_com
    GROUP BY ocsge_brut_agrege_com.nom_scot, ocsge_brut_agrege_com.nom_departement
    UNION ALL
    -- Agrégation par Région
    SELECT 
        NULL::character varying AS insee_com,
        NULL::character varying AS nom_commune,
        NULL::character varying AS nom_epci,
        NULL::character varying AS nom_scot,
        'Région'::text AS type_territoire,
        'Bretagne'::character varying AS territoire,
        NULL::character varying AS nom_departement,
        NULL::geometry AS centroid_geom,
        8 AS z,
        MIN(ocsge_brut_agrege_com.millesime_debut) AS millesime_debut,
        MAX(ocsge_brut_agrege_com.millesime_fin) AS millesime_fin,
        date_part('year'::text, MIN(ocsge_brut_agrege_com.millesime_debut)) AS annee_debut,
        date_part('year'::text, MAX(ocsge_brut_agrege_com.millesime_fin)) AS annee_fin
    FROM visufoncier.ocsge_brut_agrege_com
)
SELECT 
    aggregated_geom.insee_com,
    aggregated_geom.nom_commune,
    aggregated_geom.nom_epci,
    aggregated_geom.nom_scot,
    aggregated_geom.type_territoire,
    aggregated_geom.territoire,
    aggregated_geom.nom_departement,
    aggregated_geom.millesime_debut,
    aggregated_geom.millesime_fin,
    aggregated_geom.annee_debut,
    aggregated_geom.annee_fin,
    ROUND(ST_X(ST_Transform(aggregated_geom.centroid_geom, 3857))::numeric, 4) AS x,
    ROUND(ST_Y(ST_Transform(aggregated_geom.centroid_geom, 3857))::numeric, 4) AS y,
    aggregated_geom.z::numeric AS z
FROM aggregated_geom
WITH DATA;

COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_agrege_com_liengeo_view IS 'Vue matérialisée utilisée pour la gestion des filtres géographiques et temporels des données OCS GE dans le tableau de bord Superset Visufoncier. Cette vue permet de lier les données géographiques (communes) avec les informations temporelles nécessaires pour le filtrage et l''analyse dans le tableau de bord, facilitant l''exploration et la visualisation des données OCS GE selon des critères géographiques et temporels.';



--Vue matérialisée flux d'artificialisation


--creation de vue   
----------------------
   DROP MATERIALIZED VIEW IF EXISTS visufoncier.ocsge_fluxartif_desartif_net_view;
CREATE MATERIALIZED VIEW visufoncier.ocsge_fluxartif_desartif_net_view
TABLESPACE pg_default AS
SELECT
    insee_com,
    nom_commune,
    nom_epci,
    nom_scot,
    nom_departement,
    millesime_debut,
    millesime_fin,
    SUM(CASE
        WHEN artif_debut = 'non artif' AND artif_fin = 'artif' THEN ST_Area(geom) / 10000
        ELSE 0
    END) AS flux_artif,
    SUM(CASE
        WHEN artif_debut = 'artif' AND artif_fin = 'non artif' THEN ST_Area(geom) / 10000
        ELSE 0
    END) AS flux_desartif,
    SUM(CASE
        WHEN artif_debut = 'non artif' AND artif_fin = 'artif' THEN ST_Area(geom) / 10000
        ELSE 0
    END) - SUM(CASE
        WHEN artif_debut = 'artif' AND artif_fin = 'non artif' THEN ST_Area(geom) / 10000
        ELSE 0
    END) AS flux_artif_net
FROM visufoncier.ocsge_diff
WHERE insee_com IS NOT NULL  -- Condition to exclude rows with NULL insee_com
GROUP BY
    insee_com, nom_commune, nom_epci, nom_scot, nom_departement, millesime_debut, millesime_fin
WITH DATA;



--vérification sur une commune    
select sum(st_area(geom))/10000
from visufoncier.ocsge_diff od 
where artif_fin='artif' and artif_debut='non artif'
and insee_com ='35024'
select sum(st_area(geom))/10000
from visufoncier.ocsge_diff od 
where artif_fin='non artif' and artif_debut='artif'
and insee_com ='35024'

DROP MATERIALIZED VIEW IF EXISTS visufoncier.ocsge_fluxartif_desartif_cs_us_view;

CREATE MATERIALIZED VIEW visufoncier.ocsge_fluxartif_desartif_cs_us_view
TABLESPACE pg_default AS
SELECT
    insee_com,
    nom_commune,
    nom_epci,
    nom_scot,
    nom_departement,
    millesime_debut,
    millesime_fin,
    artif_debut,
    artif_fin,
    us_fin,
    us_debut,
    cs_fin,
    cs_debut,
    us_fin_lib,
    us_debut_lib,
    cs_fin_lib,
    cs_debut_lib,
    cs_regroup1_fin,
    cs_regroup1_debut,
    cs_regroup2_fin,
    cs_regroup2_debut,
    cs_regroup3_fin,
    cs_regroup3_debut,
    us_regroup1_fin,
    us_regroup1_debut,
    CONCAT(cs_debut_lib, '-', us_debut_lib) AS cs_us_debut,  -- Combined variable
    CONCAT(cs_fin_lib, '-', us_fin_lib) AS cs_us_fin,  -- Combined variable
    SUM(CASE
        WHEN artif_debut = 'non artif' AND artif_fin = 'artif' THEN ST_Area(geom) / 10000
        ELSE 0
    END) AS flux_artif,
    SUM(CASE
        WHEN artif_debut = 'artif' AND artif_fin = 'non artif' THEN ST_Area(geom) / 10000
        ELSE 0
    END) AS flux_desartif,
    SUM(CASE
        WHEN artif_debut = 'non artif' AND artif_fin = 'artif' THEN ST_Area(geom) / 10000
        ELSE 0
    END) - SUM(CASE
        WHEN artif_debut = 'artif' AND artif_fin = 'non artif' THEN ST_Area(geom) / 10000
        ELSE 0
    END) AS flux_artif_net
FROM visufoncier.ocsge_diff
WHERE insee_com IS NOT NULL  -- Condition to exclude rows with NULL insee_com
GROUP BY
    insee_com, nom_commune, nom_epci, nom_scot, nom_departement, millesime_debut, millesime_fin,us_fin,us_debut,cs_fin,cs_debut,us_fin_lib,us_debut_lib,cs_fin_lib,cs_debut_lib,artif_debut,artif_fin,cs_regroup1_fin,cs_regroup1_debut,cs_regroup2_fin,cs_regroup2_debut,cs_regroup3_fin,cs_regroup3_debut,us_regroup1_fin,us_regroup1_debut
WITH DATA;

COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_fluxartif_desartif_net_view IS 'Vue matérialisée calculant les flux de surfaces artificialisées et désartificialisées nettes par commune, sur la période étudiée, en fonction des millésimes de début et de fin.';
COMMENT ON MATERIALIZED VIEW visufoncier.ocsge_fluxartif_desartif_cs_us_view IS 'Vue matérialisée calculant les flux de surfaces artificialisées et désartificialisées nettes par commune, en fonction des catégories d''usages et des codes couverture, sur la période étudiée.';
