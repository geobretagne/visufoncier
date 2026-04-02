-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TRAITEMENT DES DONNÉES DU MODE D'OCCUPATION DU SOL BRETON SUR PostgreSQL --
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--TOUTES LES TABLES COMMENCANT PAR V2_


-- ========================================
-- CORRECTION DES FUSIONS DE COMMUNE
-- ========================================

-- ÉTAPE 1 : Ajouter colonne de suivi
ALTER TABLE visufoncier.mos_foncier_2024 
ADD COLUMN IF NOT EXISTS updated INTEGER DEFAULT 0;

-- CAS 1 : Marquer les fusions avec changement de code (prendre la plus récente)
UPDATE visufoncier.mos_foncier_2024 AS m
SET updated = 1
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom_2025 AS vf 
    WHERE vf.com_ini = m.code_insee_2024  -- La commune source existe dans notre table
      AND vf.com_ini <> vf.com_fin  -- C'est une vraie fusion (code change)
      AND vf.annee_modif = (
          -- Prendre la fusion la plus récente pour cette commune
          SELECT MAX(vf2.annee_modif)
          FROM visufoncier.insee_fusioncom_2025 AS vf2
          WHERE vf2.com_ini = m.code_insee_2024
            AND vf2.com_ini <> vf2.com_fin
      )
);

-- CAS 2 : Marquer les changements de nom uniquement (prendre le plus récent)
UPDATE visufoncier.mos_foncier_2024 AS m
SET updated = 2
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom_2025 AS vf 
    WHERE vf.com_ini = m.code_insee_2024
      AND vf.com_ini = vf.com_fin  -- Code identique
      AND vf.lib_com_ini <> vf.lib_com_fin  -- Mais nom différent
      AND m.nom_commune_2024 <> vf.lib_com_fin  -- ET le nom n'est pas déjà à jour
      AND vf.annee_modif = (
          -- Prendre la modification la plus récente
          SELECT MAX(vf2.annee_modif)
          FROM visufoncier.insee_fusioncom_2025 AS vf2
          WHERE vf2.com_ini = m.code_insee_2024
            AND vf2.com_ini = vf2.com_fin
            AND vf2.lib_com_ini <> vf2.lib_com_fin
      )
);

-- VÉRIFICATION : Voir les communes qui vont être modifiées
SELECT DISTINCT
    m.code_insee_2024,
    m.nom_commune_2024,
    m.updated,
    vf.com_fin as nouveau_code,
    vf.lib_com_fin as nouveau_nom,
    COUNT(*) as nb_polygones
FROM visufoncier.mos_foncier_2024 m
LEFT JOIN visufoncier.insee_fusioncom_2025 vf 
    ON vf.com_ini = m.code_insee_2024
    AND vf.annee_modif = (
        SELECT MAX(vf2.annee_modif)
        FROM visufoncier.insee_fusioncom_2025 vf2
        WHERE vf2.com_ini = m.code_insee_2024
    )
WHERE m.updated > 0
GROUP BY m.code_insee_2024, m.nom_commune_2024, m.updated, vf.com_fin, vf.lib_com_fin
ORDER BY m.updated, m.code_insee_2024;

-- ========================================
-- SI LA VÉRIFICATION EST OK, LANCER LES CORRECTIONS :
-- ========================================

-- CORRECTION CAS 1 : Fusion avec changement de code
UPDATE visufoncier.mos_foncier_2024 AS m
SET 
    code_insee_2024 = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = m.code_insee_2024
          AND vf.com_ini <> vf.com_fin
        ORDER BY vf.annee_modif DESC
        LIMIT 1
    ),
    nom_commune_2024 = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = m.code_insee_2024
          AND vf.com_ini <> vf.com_fin
        ORDER BY vf.annee_modif DESC
        LIMIT 1
    )
WHERE updated = 1;

-- CORRECTION CAS 2 : Changement de nom uniquement
UPDATE visufoncier.mos_foncier_2024 AS m
SET 
    nom_commune_2024 = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = m.code_insee_2024
          AND vf.com_ini = vf.com_fin
          AND vf.lib_com_ini <> vf.lib_com_fin
        ORDER BY vf.annee_modif DESC
        LIMIT 1
    )
WHERE updated = 2;

-- VÉRIFICATION FINALE : Voir les résultats
SELECT DISTINCT
    code_insee_2024,
    nom_commune_2024,
    COUNT(*) as nb_polygones
FROM visufoncier.mos_foncier_2024
WHERE updated > 0
GROUP BY code_insee_2024, nom_commune_2024
ORDER BY code_insee_2024;

-- =====================================================
-- RECALCUL DES TYPE_CONSO À PARTIR DE CONS_ENAF
-- =====================================================

-- Recalculer les colonnes type_conso par année à partir de la nouvelle nomenclature.

--!!!!!!!!!!!!!!!ATTENTION, A RECALCULER SI NOUVELLE NOMENCLATURE, NOUVEAU CODE !!!!!!!!!!!

ALTER TABLE visufoncier.mos_foncier_2024
ADD COLUMN IF NOT EXISTS type_conso_2011 VARCHAR(10),
ADD COLUMN IF NOT EXISTS type_conso_2021 VARCHAR(10),
ADD COLUMN IF NOT EXISTS type_conso_2024 VARCHAR(10);

UPDATE visufoncier.mos_foncier_2024
SET 
    type_conso_2011 = CASE
        WHEN code4_2011::text IN ('1131', '1311', '1334', '1423', 
                                  '2121', '2511', 
                                  '3251', '3261', '3311', '3321', 
                                  '5121', '5131', '5231', '5232', '5233', '5234') THEN 'enaf'
        ELSE 'conso'
    END,
    type_conso_2021 = CASE
        WHEN code4_2021::text IN ('1131', '1311', '1334', '1423', 
                                  '2121', '2511', 
                                  '3251', '3261', '3311', '3321', 
                                  '5121', '5131', '5231', '5232', '5233', '5234') THEN 'enaf'
        ELSE 'conso'
    END,
    type_conso_2024 = CASE
        WHEN code4_2024::text IN ('1131', '1311', '1334', '1423', 
                                  '2121', '2511', 
                                  '3251', '3261', '3311', '3321', 
                                  '5121', '5131', '5231', '5232', '5233', '5234') THEN 'enaf'
        ELSE 'conso'
    END;
	
--correction à partir de la variable cons_enaf (revoir avec Sylvain si tjrs ok ! )

-- CAS 1 : Corriger type_conso_2024 (enaf→enaf→enaf→CONSO devient enaf)
UPDATE visufoncier.mos_foncier_2024
SET type_conso_2024 = 'enaf'
WHERE cons_enaf = 'enaf' 
  AND type_conso_2011 = 'enaf' 
  AND type_conso_2021 = 'enaf' 
  AND type_conso_2024 = 'conso';

-- CAS 2 : Corriger type_conso_2011 ET type_conso_2024
UPDATE visufoncier.mos_foncier_2024
SET 
    type_conso_2011 = 'enaf',
    type_conso_2024 = 'enaf'
WHERE cons_enaf = 'enaf' 
  AND type_conso_2011 = 'conso' 
  AND type_conso_2024 = 'conso';

-------------------------------------------------------------------------------------------------------------
-- Création table agrégée avec pivot temporel
-------------------------------------------
DROP TABLE IF EXISTS visufoncier.v2_mos_agrege CASCADE;

CREATE TABLE visufoncier.v2_mos_agrege AS
WITH aggregated AS (
    SELECT
        code_insee_2024,
        nom_commune_2024,
        code4_2011::integer, code4_2021::integer, code4_2024::integer,
        regroup_2011, regroup_2021, regroup_2024,
        lib4_2011, lib4_2021, lib4_2024,
        type_conso_2011, type_conso_2021, type_conso_2024,
        cons_enaf,
        SUM(surface_m2_2024) / 10000 as surface_ha,
        ROW_NUMBER() OVER () as groupe_id
    FROM visufoncier.mos_foncier_2024
    GROUP BY code_insee_2024, nom_commune_2024, 
             code4_2011, code4_2021, code4_2024,
             regroup_2011, regroup_2021, regroup_2024,
             lib4_2011, lib4_2021, lib4_2024,
             type_conso_2011, type_conso_2021, type_conso_2024,
             cons_enaf
)
SELECT 
    code_insee_2024 as insee_com,
    nom_commune_2024 as nom_commune,
    groupe_id,
    millesime.annee::TIMESTAMP as annee,
    millesime.code4,
    millesime.nature,
    millesime.nature_det,
    CASE 
        WHEN millesime.type_conso = 'enaf' THEN 'enaf'
        WHEN millesime.type_conso = 'conso' THEN 'conso'
        ELSE NULL
    END as enaf_conso,
    CASE 
        WHEN cons_enaf = 'cons enaf 2011-2021' THEN 'Consommation 2011-2021'
        WHEN cons_enaf = 'cons enaf 2011-2021 INFRA' THEN 'Infrastructure 2011-2021'
        WHEN cons_enaf = 'cons enaf 2021-2024' THEN 'Consommation 2021-2024'
        WHEN cons_enaf = 'cons enaf 2021-2024 PENE' THEN 'PENE 2021-2024'
        WHEN cons_enaf = 'cons enaf 2021-2024 PER' THEN 'PER 2021-2024'
        WHEN cons_enaf = 'enaf' THEN 'ENAF (non consommé)'
        WHEN cons_enaf = 'non enaf en 2011' THEN 'Déjà consommé en 2011'
        ELSE NULL
    END as type_consommation,
    surface_ha
FROM aggregated
CROSS JOIN LATERAL (
    VALUES 
        ('2011-01-01'::TIMESTAMP, code4_2011, regroup_2011, lib4_2011, type_conso_2011),
        ('2021-01-01'::TIMESTAMP, code4_2021, regroup_2021, lib4_2021, type_conso_2021),
        ('2024-01-01'::TIMESTAMP, code4_2024, regroup_2024, lib4_2024, type_conso_2024)
) AS millesime(annee, code4, nature, nature_det, type_conso);

-- Index
CREATE INDEX idx_v2_mos_insee ON visufoncier.v2_mos_agrege (insee_com);
CREATE INDEX idx_v2_mos_annee ON visufoncier.v2_mos_agrege (annee);
CREATE INDEX idx_v2_mos_groupe ON visufoncier.v2_mos_agrege (groupe_id);
CREATE INDEX idx_v2_mos_enaf ON visufoncier.v2_mos_agrege (enaf_conso);

COMMENT ON TABLE visufoncier.v2_mos_agrege IS 
'Table pivot MOS 2024 : 3 lignes par polygone (2011, 2021, 2024) avec enaf_conso et type_consommation';


--droits
-- Accorder le droit de sélection (SELECT) à l'utilisateur "app-visufoncier"
-- Cet utilisateur est celui qui lancera les requêtes depuis l'application Superset.
-- Il est important de ne pas accorder des droits excessifs, comme "GRANT ALL", 
-- afin de limiter les permissions uniquement aux opérations nécessaires.
GRANT SELECT ON TABLE visufoncier.v2_mos_agrege TO "app-visufoncier";

-- Accorder tous les droits (ALL) à l'utilisateur "margot.leborgne". Remplacer margot.leborgne par votre nom d'utilisateur
-- Cet utilisateur peut avoir besoin de droits supplémentaires pour des opérations variées.
-- Vérifier que cet utilisateur a la responsabilité d'effectuer des modifications sur la table.
GRANT ALL ON TABLE visufoncier.v2_mos_agrege TO "margot.leborgne";

-- Accorder le droit de sélection (SELECT) à l'utilisateur "www-data"
-- Cet utilisateur est souvent utilisé par le serveur web pour accéder aux données nécessaires.
GRANT SELECT ON TABLE visufoncier.v2_mos_agrege TO "www-data";

-- vérif 
SELECT * FROM visufoncier.v2_mos_agrege LIMIT 10;

-- Chaque groupe_id doit avoir exactement 3 lignes
SELECT groupe_id, COUNT(*) as nb_lignes
FROM visufoncier.v2_mos_agrege
GROUP BY groupe_id
HAVING COUNT(*) != 3;

--2eme étape

-- v&rif enaf conso

-- Croisement vérif de type conso entre 2011 2021 2024
SELECT 
    cons_enaf,
    type_conso_2011,
    type_conso_2021,
    type_conso_2024,
    COUNT(*) as nb_lignes
FROM visufoncier.mos_foncier_2024
GROUP BY cons_enaf, type_conso_2011, type_conso_2021, type_conso_2024
ORDER BY cons_enaf, type_conso_2011, type_conso_2021, type_conso_2024;


-- Vérification
SELECT annee, enaf_conso, COUNT(*), ROUND(SUM(surface_ha)::numeric, 2) as surface_ha
FROM visufoncier.v2_mos_agrege
GROUP BY annee, enaf_conso
ORDER BY annee, enaf_conso;



--Passer à la récupération des scot, epci, dep...

-- Ajouter les colonnes manquantes
ALTER TABLE visufoncier.v2_mos_agrege
ADD COLUMN IF NOT EXISTS siren_epci VARCHAR,
ADD COLUMN IF NOT EXISTS insee_dep VARCHAR,
ADD COLUMN IF NOT EXISTS insee_reg VARCHAR,
ADD COLUMN IF NOT EXISTS nom_epci VARCHAR,
ADD COLUMN IF NOT EXISTS nom_scot VARCHAR,
ADD COLUMN IF NOT EXISTS nom_departement VARCHAR;

-- Mise à jour nom_departement
UPDATE visufoncier.v2_mos_agrege
SET nom_departement = CASE
    WHEN LEFT(insee_com, 2) = '35' THEN 'Ille-et-Vilaine'
    WHEN LEFT(insee_com, 2) = '22' THEN 'Côtes-d''Armor'
    WHEN LEFT(insee_com, 2) = '56' THEN 'Morbihan'
    WHEN LEFT(insee_com, 2) = '29' THEN 'Finistère'
END;

-- Jointure Admin Express
UPDATE visufoncier.v2_mos_agrege t
SET 
    siren_epci = c.siren_epci,
    insee_dep = c.insee_dep,
    insee_reg = c.insee_reg
FROM ign.express_commune c
WHERE t.insee_com = c.insee_com;

-- Jointure EPCI
UPDATE visufoncier.v2_mos_agrege t
SET nom_epci = e.nom_epci
FROM ign.express_epci e
WHERE t.siren_epci = e.code_epci;

-- Jointure SCOT
UPDATE visufoncier.v2_mos_agrege t
SET nom_scot = ff.scot
FROM visufoncier.ff_obs_artif_conso_com_2009_2024 ff
WHERE t.insee_com = ff.idcom;

-- Vérification
SELECT insee_com, nom_commune, nom_epci, nom_scot, nom_departement, COUNT(*)
FROM visufoncier.v2_mos_agrege
GROUP BY insee_com, nom_commune, nom_epci, nom_scot, nom_departement
LIMIT 10;



-- Vue flux dynamique 
DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_flux CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_flux AS
SELECT 
    m1.insee_com,
    m1.nom_commune,
    m1.nom_epci,
    m1.nom_scot,
    m1.nom_departement,
    m1.insee_dep,
    m1.insee_reg,
    m1.annee as annee_debut,
    m2.annee as annee_fin,
    m1.code4 as code4_debut,
    m2.code4 as code4_fin,
    m1.nature as nature_debut,
    m2.nature as nature_fin,
    m1.nature_det as nature_det_debut,
    m2.nature_det as nature_det_fin,
    m1.enaf_conso as enaf_conso_debut,
    m2.enaf_conso as enaf_conso_fin,
    -- Calcul flux
    CASE WHEN m1.enaf_conso = 'enaf' AND m2.enaf_conso = 'conso' THEN 1 ELSE 0 END as flux_conso,
    CASE WHEN m1.enaf_conso = 'conso' AND m2.enaf_conso = 'enaf' THEN 1 ELSE 0 END as flux_renaturation,
    m1.surface_ha,
    m1.groupe_id
FROM visufoncier.v2_mos_agrege m1
JOIN visufoncier.v2_mos_agrege m2 
    ON m1.groupe_id = m2.groupe_id
    AND m2.annee > m1.annee;

-- Index
CREATE INDEX idx_v2_flux_insee ON visufoncier.v2_mos_flux (insee_com);
CREATE INDEX idx_v2_flux_annees ON visufoncier.v2_mos_flux (annee_debut, annee_fin);
CREATE INDEX idx_v2_flux_conso ON visufoncier.v2_mos_flux (flux_conso);
CREATE INDEX idx_v2_flux_epci ON visufoncier.v2_mos_flux (nom_epci);
CREATE INDEX idx_v2_flux_scot ON visufoncier.v2_mos_flux (nom_scot);
CREATE INDEX idx_v2_flux_dep ON visufoncier.v2_mos_flux (insee_dep);

COMMENT ON MATERIALIZED VIEW visufoncier.v2_mos_flux IS
'TEST - Flux détaillés avec toutes variables géographiques';


--droits
-- Accorder le droit de sélection (SELECT) à l'utilisateur "app-visufoncier"
-- Cet utilisateur est celui qui lancera les requêtes depuis l'application Superset.
-- Il est important de ne pas accorder des droits excessifs, comme "GRANT ALL", 
-- afin de limiter les permissions uniquement aux opérations nécessaires.
GRANT SELECT ON TABLE visufoncier.v2_mos_flux TO "app-visufoncier";

-- Accorder tous les droits (ALL) à l'utilisateur "margot.leborgne". Remplacer margot.leborgne par votre nom d'utilisateur
-- Cet utilisateur peut avoir besoin de droits supplémentaires pour des opérations variées.
-- Vérifier que cet utilisateur a la responsabilité d'effectuer des modifications sur la table.
GRANT ALL ON TABLE visufoncier.v2_mos_flux TO "margot.leborgne";

-- Accorder le droit de sélection (SELECT) à l'utilisateur "www-data"
-- Cet utilisateur est souvent utilisé par le serveur web pour accéder aux données nécessaires.
GRANT SELECT ON TABLE visufoncier.v2_mos_flux TO "www-data";

-- Vérification
SELECT annee_debut, annee_fin, COUNT(*) as nb_lignes
FROM visufoncier.v2_mos_flux
GROUP BY annee_debut, annee_fin;

--Vue principale flux commune

DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_flux_com CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_flux_com AS
SELECT 
    f.insee_com,
    f.nom_commune,
    f.nom_epci,
    f.nom_scot,
    f.nom_departement,
    f.insee_dep,
    f.insee_reg,
    f.annee_debut,
    f.annee_fin,
    m.type_consommation,
    SUM(f.flux_conso) as nb_flux_conso,
    COALESCE(ROUND(SUM(CASE WHEN f.flux_conso = 1 THEN f.surface_ha END)::numeric, 2), 0) as surf_consommee_ha,
    COALESCE(ROUND(SUM(CASE WHEN f.flux_conso = 1 
                   AND m.type_consommation NOT IN (
                       'Infrastructure 2011-2021',
                       'PENE 2021-2024',
                       'PER 2021-2024'
                   ) THEN f.surface_ha END)::numeric, 2), 0) as surf_consommee_ha_exclu,
    SUM(f.flux_renaturation) as nb_flux_renaturation,
    COALESCE(ROUND(SUM(CASE WHEN f.flux_renaturation = 1 THEN f.surface_ha END)::numeric, 2), 0) as surf_renaturee_ha,
    COUNT(*) as nb_polygones_total,
    MAX(f.flux_conso) as a_flux_conso,
    MAX(f.flux_renaturation) as a_flux_renaturation
FROM visufoncier.v2_mos_flux f
LEFT JOIN visufoncier.v2_mos_agrege m 
    ON f.groupe_id = m.groupe_id 
    AND f.annee_fin = m.annee
GROUP BY f.insee_com, f.nom_commune, f.nom_epci, f.nom_scot, f.nom_departement, 
         f.insee_dep, f.insee_reg, f.annee_debut, f.annee_fin, m.type_consommation;

CREATE INDEX idx_v2_flux_com_insee ON visufoncier.v2_mos_flux_com (insee_com);
CREATE INDEX idx_v2_flux_com_type ON visufoncier.v2_mos_flux_com (type_consommation);

GRANT SELECT ON visufoncier.v2_mos_flux_com TO "app-visufoncier";
GRANT ALL ON visufoncier.v2_mos_flux_com TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_mos_flux_com TO "www-data";

COMMENT ON MATERIALIZED VIEW visufoncier.v2_mos_flux_com IS
'Flux agrégés par commune avec surf_consommee_ha (totale) et surf_consommee_ha_exclu (sans INFRA/PENE/PER). 0 au lieu de NULL quand aucune consommation sur la période.';

--vérification commune
-- Vue détaillée Guichen
SELECT *
FROM visufoncier.v2_mos_flux_com
WHERE nom_commune = 'Guichen'
ORDER BY annee_debut, annee_fin;

