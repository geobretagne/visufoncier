-- Traitement FF X MOS

--On va utiliser maintenant uniquement les TUP POLYGONES (on laisse les PEV que pour 2011)
--On utilise l'année la plus récente pour le calcul (pour 2024 on a pris TUP 2025)


--Partie préalable au traitement : simplification et correction des geométries TUP
-- ============================================================
-- TUP 2021 SIMPLIFIÉ
-- ============================================================

DROP TABLE IF EXISTS visufoncier_private.ffta_tup_2021_polygones_simple CASCADE;

CREATE TABLE visufoncier_private.ffta_tup_2021_polygones_simple (
    idtup    text,
    idcom    varchar,
    nlogh    integer,
    geom     geometry(MultiPolygon, 2154)
);

-- Département 22
INSERT INTO visufoncier_private.ffta_tup_2021_polygones_simple
SELECT
    idtup, idcom, nlogh,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SimplifyPreserveTopology(ST_SnapToGrid(geom, 0.01), 0.5)), 3))::geometry(MultiPolygon, 2154)
FROM visufoncier_private.ffta_tup_2021_polygones
WHERE geom IS NOT NULL AND LEFT(idcom, 2) = '22';
COMMIT;

-- Département 29
INSERT INTO visufoncier_private.ffta_tup_2021_polygones_simple
SELECT
    idtup, idcom, nlogh,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SimplifyPreserveTopology(ST_SnapToGrid(geom, 0.01), 0.5)), 3))::geometry(MultiPolygon, 2154)
FROM visufoncier_private.ffta_tup_2021_polygones
WHERE geom IS NOT NULL AND LEFT(idcom, 2) = '29';
COMMIT;

-- Département 35
INSERT INTO visufoncier_private.ffta_tup_2021_polygones_simple
SELECT
    idtup, idcom, nlogh,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SimplifyPreserveTopology(ST_SnapToGrid(geom, 0.01), 0.5)), 3))::geometry(MultiPolygon, 2154)
FROM visufoncier_private.ffta_tup_2021_polygones
WHERE geom IS NOT NULL AND LEFT(idcom, 2) = '35';
COMMIT;

-- Département 56
INSERT INTO visufoncier_private.ffta_tup_2021_polygones_simple
SELECT
    idtup, idcom, nlogh,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SimplifyPreserveTopology(ST_SnapToGrid(geom, 0.01), 0.5)), 3))::geometry(MultiPolygon, 2154)
FROM visufoncier_private.ffta_tup_2021_polygones
WHERE geom IS NOT NULL AND LEFT(idcom, 2) = '56';
COMMIT;

-- Nettoyage
DELETE FROM visufoncier_private.ffta_tup_2021_polygones_simple
WHERE geom IS NULL OR ST_IsEmpty(geom);
COMMIT;

-- Index
CREATE INDEX idx_tup_2021_simple_geom  ON visufoncier_private.ffta_tup_2021_polygones_simple USING gist (geom);
CREATE INDEX idx_tup_2021_simple_idcom ON visufoncier_private.ffta_tup_2021_polygones_simple USING btree (idcom);
CREATE INDEX idx_tup_2021_simple_idtup ON visufoncier_private.ffta_tup_2021_polygones_simple USING btree (idtup);

-- Vérification
SELECT 
    LEFT(idcom, 2)                               AS dep,
    COUNT(*)                                     AS nb_tup,
    COUNT(*) FILTER (WHERE NOT ST_IsValid(geom)) AS nb_invalides,
    SUM(nlogh)                                   AS total_logements
FROM visufoncier_private.ffta_tup_2021_polygones_simple
GROUP BY LEFT(idcom, 2)
ORDER BY dep;


-- ============================================================
-- TUP 2025 SIMPLIFIÉ
-- Source : geomtup (pas geom), pas déclarée en multipolygon
-- ============================================================

DROP TABLE IF EXISTS visufoncier_private.ffta_tup_2025_polygones_simple CASCADE;

CREATE TABLE visufoncier_private.ffta_tup_2025_polygones_simple (
    idtup    text,
    idcom    varchar,
    nlogh    integer,
    geom     geometry(MultiPolygon, 2154)
);

-- Département 22
INSERT INTO visufoncier_private.ffta_tup_2025_polygones_simple
SELECT
    idtup, idcom, nlogh,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SimplifyPreserveTopology(ST_SnapToGrid(geomtup, 0.01), 0.5)), 3))::geometry(MultiPolygon, 2154)
FROM visufoncier_private.ffta_tup_2025_polygones
WHERE geomtup IS NOT NULL AND LEFT(idcom, 2) = '22';
COMMIT;

-- Département 29
INSERT INTO visufoncier_private.ffta_tup_2025_polygones_simple
SELECT
    idtup, idcom, nlogh,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SimplifyPreserveTopology(ST_SnapToGrid(geomtup, 0.01), 0.5)), 3))::geometry(MultiPolygon, 2154)
FROM visufoncier_private.ffta_tup_2025_polygones
WHERE geomtup IS NOT NULL AND LEFT(idcom, 2) = '29';
COMMIT;

-- Département 35
INSERT INTO visufoncier_private.ffta_tup_2025_polygones_simple
SELECT
    idtup, idcom, nlogh,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SimplifyPreserveTopology(ST_SnapToGrid(geomtup, 0.01), 0.5)), 3))::geometry(MultiPolygon, 2154)
FROM visufoncier_private.ffta_tup_2025_polygones
WHERE geomtup IS NOT NULL AND LEFT(idcom, 2) = '35';
COMMIT;

-- Département 56
INSERT INTO visufoncier_private.ffta_tup_2025_polygones_simple
SELECT
    idtup, idcom, nlogh,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_SimplifyPreserveTopology(ST_SnapToGrid(geomtup, 0.01), 0.5)), 3))::geometry(MultiPolygon, 2154)
FROM visufoncier_private.ffta_tup_2025_polygones
WHERE geomtup IS NOT NULL AND LEFT(idcom, 2) = '56';
COMMIT;

-- Nettoyage
DELETE FROM visufoncier_private.ffta_tup_2025_polygones_simple
WHERE geom IS NULL OR ST_IsEmpty(geom);
COMMIT;

-- Index
CREATE INDEX idx_tup_2025_simple_geom  ON visufoncier_private.ffta_tup_2025_polygones_simple USING gist (geom);
CREATE INDEX idx_tup_2025_simple_idcom ON visufoncier_private.ffta_tup_2025_polygones_simple USING btree (idcom);
CREATE INDEX idx_tup_2025_simple_idtup ON visufoncier_private.ffta_tup_2025_polygones_simple USING btree (idtup);

-- Vérification
SELECT 
    LEFT(idcom, 2)                               AS dep,
    COUNT(*)                                     AS nb_tup,
    COUNT(*) FILTER (WHERE NOT ST_IsValid(geom)) AS nb_invalides,
    SUM(nlogh)                                   AS total_logements
FROM visufoncier_private.ffta_tup_2025_polygones_simple
GROUP BY LEFT(idcom, 2)
ORDER BY dep;


--Premiere partie : calcul du nombre de logement par commune pour la densite de logement (onglet indicateur)

-- ============================================================
-- ÉTAPE 1 : NB LOGEMENTS 2011 PAR COMMUNE - PEV
-- ============================================================

DROP TABLE IF EXISTS visufoncier.v2_ff_nblogh11_com CASCADE;

CREATE TABLE visufoncier.v2_ff_nblogh11_com AS
SELECT idcom, idcomtxt, COUNT(*) AS nlogh
FROM (
    SELECT DISTINCT idcom, idcomtxt, idlocal
    FROM visufoncier_private.d22_2011_pb21_pev
    WHERE dnupev = '001' AND ccoaff = 'H'
    UNION ALL
    SELECT DISTINCT idcom, idcomtxt, idlocal
    FROM visufoncier_private.d29_2011_pb21_pev
    WHERE dnupev = '001' AND ccoaff = 'H'
    UNION ALL
    SELECT DISTINCT idcom, idcomtxt, idlocal
    FROM visufoncier_private.d35_2011_pb21_pev
    WHERE dnupev = '001' AND ccoaff = 'H'
    UNION ALL
    SELECT DISTINCT idcom, idcomtxt, idlocal
    FROM visufoncier_private.d56_2011_pb21_pev
    WHERE dnupev = '001' AND ccoaff = 'H'
) AS p
GROUP BY idcom, idcomtxt;

COMMENT ON TABLE visufoncier.v2_ff_nblogh11_com IS
'Nombre de logements par commune 2011 issu des PEV (dnupev=001 et ccoaff=H). Fusions de communes 2025 appliquées.';

-- Fusions 2011
ALTER TABLE visufoncier.v2_ff_nblogh11_com
ADD COLUMN IF NOT EXISTS updated BOOLEAN DEFAULT FALSE;

DROP TABLE IF EXISTS temp_fusion;
CREATE TEMPORARY TABLE temp_fusion AS
SELECT vf.com_fin AS idcom, vf.lib_com_fin AS idcomtxt, SUM(vn.nlogh) AS nlogh
FROM visufoncier.insee_fusioncom_2025 vf
JOIN visufoncier.v2_ff_nblogh11_com vn ON vf.com_ini = vn.idcom
GROUP BY vf.com_fin, vf.lib_com_fin;

INSERT INTO temp_fusion (idcom, idcomtxt, nlogh)
SELECT vn.idcom, vn.idcomtxt, vn.nlogh
FROM visufoncier.v2_ff_nblogh11_com vn
WHERE vn.idcom NOT IN (SELECT com_ini FROM visufoncier.insee_fusioncom_2025);

UPDATE visufoncier.v2_ff_nblogh11_com SET updated = TRUE
WHERE idcom IN (SELECT com_ini FROM visufoncier.insee_fusioncom_2025);

DELETE FROM visufoncier.v2_ff_nblogh11_com WHERE updated = TRUE;

INSERT INTO visufoncier.v2_ff_nblogh11_com (idcom, idcomtxt, nlogh)
SELECT idcom, idcomtxt, nlogh FROM temp_fusion;

DROP TABLE temp_fusion;

DELETE FROM visufoncier.v2_ff_nblogh11_com
WHERE ctid NOT IN (
    SELECT MIN(ctid) FROM visufoncier.v2_ff_nblogh11_com
    GROUP BY idcom, idcomtxt, nlogh
);

ALTER TABLE visufoncier.v2_ff_nblogh11_com DROP COLUMN updated;

-- Vérification
SELECT COUNT(*) AS nb_communes, SUM(nlogh) AS total_logements
FROM visufoncier.v2_ff_nblogh11_com;

-- Dans les PEV 2011 bruts
SELECT idcom, idcomtxt, COUNT(DISTINCT idlocal) AS nlogh
FROM visufoncier_private.d22_2011_pb21_pev
WHERE idcom IN ('22309', '22147')
  AND dnupev = '001' AND ccoaff = 'H'
GROUP BY idcom, idcomtxt;

-- Dans la table fusionnée v2_ff_nblogh11_com
SELECT idcom, idcomtxt, nlogh
FROM visufoncier.v2_ff_nblogh11_com
WHERE idcom IN ('22178', '22231',
    (SELECT DISTINCT com_fin FROM visufoncier.insee_fusioncom_2025 
     WHERE com_ini IN ('22178', '22231'))
);
-- ============================================================
-- ÉTAPE 2 : NB LOGEMENTS 2021 PAR COMMUNE - TUP
-- ============================================================

DROP TABLE IF EXISTS visufoncier.v2_ff_nblogh21_com CASCADE;

CREATE TABLE visufoncier.v2_ff_nblogh21_com AS
SELECT idcom, SUM(nlogh) AS nlogh
FROM visufoncier_private.ffta_tup_2021_polygones_simple
WHERE nlogh > 0
GROUP BY idcom;

COMMENT ON TABLE visufoncier.v2_ff_nblogh21_com IS
'Nombre de logements par commune 2021 issu des TUP (SUM nlogh). Fusions de communes 2025 appliquées.';

-- Fusions 2021
ALTER TABLE visufoncier.v2_ff_nblogh21_com
ADD COLUMN IF NOT EXISTS updated BOOLEAN DEFAULT FALSE;

DROP TABLE IF EXISTS temp_fusion;
CREATE TEMPORARY TABLE temp_fusion AS
SELECT vf.com_fin AS idcom, SUM(vn.nlogh) AS nlogh
FROM visufoncier.insee_fusioncom_2025 vf
JOIN visufoncier.v2_ff_nblogh21_com vn ON vf.com_ini = vn.idcom
GROUP BY vf.com_fin;

INSERT INTO temp_fusion (idcom, nlogh)
SELECT vn.idcom, vn.nlogh
FROM visufoncier.v2_ff_nblogh21_com vn
WHERE vn.idcom NOT IN (SELECT com_ini FROM visufoncier.insee_fusioncom_2025);

UPDATE visufoncier.v2_ff_nblogh21_com SET updated = TRUE
WHERE idcom IN (SELECT com_ini FROM visufoncier.insee_fusioncom_2025);

DELETE FROM visufoncier.v2_ff_nblogh21_com WHERE updated = TRUE;

INSERT INTO visufoncier.v2_ff_nblogh21_com (idcom, nlogh)
SELECT idcom, nlogh FROM temp_fusion;

DROP TABLE temp_fusion;

DELETE FROM visufoncier.v2_ff_nblogh21_com
WHERE ctid NOT IN (
    SELECT MIN(ctid) FROM visufoncier.v2_ff_nblogh21_com
    GROUP BY idcom, nlogh
);

ALTER TABLE visufoncier.v2_ff_nblogh21_com DROP COLUMN updated;

-- Vérification
SELECT COUNT(*) AS nb_communes, SUM(nlogh) AS total_logements
FROM visufoncier.v2_ff_nblogh21_com;


-- ============================================================
-- ÉTAPE 3 : NB LOGEMENTS 2025 PAR COMMUNE - TUP
-- ============================================================

DROP TABLE IF EXISTS visufoncier.v2_ff_nblogh25_com CASCADE;

CREATE TABLE visufoncier.v2_ff_nblogh25_com AS
SELECT idcom, SUM(nlogh) AS nlogh
FROM visufoncier_private.ffta_tup_2025_polygones_simple
WHERE nlogh > 0
GROUP BY idcom;

COMMENT ON TABLE visufoncier.v2_ff_nblogh25_com IS
'Nombre de logements par commune 2025 issu des TUP (SUM nlogh). Fusions de communes 2025 appliquées.';

-- Fusions 2025
ALTER TABLE visufoncier.v2_ff_nblogh25_com
ADD COLUMN IF NOT EXISTS updated BOOLEAN DEFAULT FALSE;

DROP TABLE IF EXISTS temp_fusion;
CREATE TEMPORARY TABLE temp_fusion AS
SELECT vf.com_fin AS idcom, SUM(vn.nlogh) AS nlogh
FROM visufoncier.insee_fusioncom_2025 vf
JOIN visufoncier.v2_ff_nblogh25_com vn ON vf.com_ini = vn.idcom
GROUP BY vf.com_fin;

INSERT INTO temp_fusion (idcom, nlogh)
SELECT vn.idcom, vn.nlogh
FROM visufoncier.v2_ff_nblogh25_com vn
WHERE vn.idcom NOT IN (SELECT com_ini FROM visufoncier.insee_fusioncom_2025);

UPDATE visufoncier.v2_ff_nblogh25_com SET updated = TRUE
WHERE idcom IN (SELECT com_ini FROM visufoncier.insee_fusioncom_2025);

DELETE FROM visufoncier.v2_ff_nblogh25_com WHERE updated = TRUE;

INSERT INTO visufoncier.v2_ff_nblogh25_com (idcom, nlogh)
SELECT idcom, nlogh FROM temp_fusion;

DROP TABLE temp_fusion;

DELETE FROM visufoncier.v2_ff_nblogh25_com
WHERE ctid NOT IN (
    SELECT MIN(ctid) FROM visufoncier.v2_ff_nblogh25_com
    GROUP BY idcom, nlogh
);

ALTER TABLE visufoncier.v2_ff_nblogh25_com DROP COLUMN updated;

-- Vérification
SELECT COUNT(*) AS nb_communes, SUM(nlogh) AS total_logements
FROM visufoncier.v2_ff_nblogh25_com;


---Vue matérialisée 

DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_foncier_2024_com_temporel_log_view CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_foncier_2024_com_temporel_log_view
TABLESPACE pg_default
AS WITH logements11 AS (
         SELECT DISTINCT ON (idcom) idcom, nlogh
           FROM visufoncier.v2_ff_nblogh11_com
          ORDER BY idcom
        ), logements21 AS (
         SELECT DISTINCT ON (idcom) idcom, nlogh
           FROM visufoncier.v2_ff_nblogh21_com
          ORDER BY idcom
        ), logements25 AS (
         SELECT DISTINCT ON (idcom) idcom, nlogh
           FROM visufoncier.v2_ff_nblogh25_com
          ORDER BY idcom
        ), habitat_agrege AS (
         SELECT v2_mos_agrege.insee_com,
            v2_mos_agrege.annee,
            sum(v2_mos_agrege.surface_ha) * 10000::double precision AS surf_hab_m2
           FROM visufoncier.v2_mos_agrege
          WHERE v2_mos_agrege.code4 IN (1112, 1113, 1222, 1331, 1413)
          GROUP BY v2_mos_agrege.insee_com, v2_mos_agrege.annee
        )
 SELECT m.insee_com,
    m.nom_commune,
    m.nom_epci,
    m.nom_scot,
    m.nom_departement,
    m.annee,
    COALESCE(m.surf_conso_ha * 10000::numeric, 0::numeric) AS surf_conso_m2,
    COALESCE(h.surf_hab_m2, 0::double precision) AS surf_hab_m2,
        CASE
            WHEN date_part('year'::text, m.annee) = 2011::double precision THEN COALESCE(log11.nlogh, 0)
            WHEN date_part('year'::text, m.annee) = 2021::double precision THEN COALESCE(log21.nlogh, 0)
            WHEN date_part('year'::text, m.annee) = 2024::double precision THEN COALESCE(log25.nlogh, 0)
            ELSE NULL::integer
        END AS nlogh
   FROM visufoncier.v2_mos_agrege_com m
     LEFT JOIN logements11 log11 ON m.insee_com = log11.idcom::text
     LEFT JOIN logements21 log21 ON m.insee_com = log21.idcom::text
     LEFT JOIN logements25 log25 ON m.insee_com = log25.idcom::text
     LEFT JOIN habitat_agrege h ON m.insee_com = h.insee_com AND m.annee = h.annee
  ORDER BY m.insee_com, m.annee
WITH DATA;

CREATE INDEX idx_v2_mos_temp_log_annee ON visufoncier.v2_mos_foncier_2024_com_temporel_log_view USING btree (annee);
CREATE INDEX idx_v2_mos_temp_log_insee ON visufoncier.v2_mos_foncier_2024_com_temporel_log_view USING btree (insee_com);

GRANT SELECT ON visufoncier.v2_mos_foncier_2024_com_temporel_log_view TO "app-visufoncier";
GRANT ALL    ON visufoncier.v2_mos_foncier_2024_com_temporel_log_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_mos_foncier_2024_com_temporel_log_view TO "www-data";

COMMENT ON MATERIALIZED VIEW visufoncier.v2_mos_foncier_2024_com_temporel_log_view IS
'Vue temporelle logements : 3 lignes par commune (2011, 2021, 2024) avec surf_conso, surf_habitat MOS et nb logements.
Habitat filtré sur codes MOS : 1112, 1113, 1222, 1331, 1413.
2011 : PEV 2011 | 2021 : TUP 2021 | 2024 : TUP 2025.';



-- Partie 2 - Attribution d'un nb de logement par parcelle conso habitat au MOS (tous les codes habitat (jardin voie de desserte...) sauf terrain vacants habitat)
SET work_mem = '512MB';

-- ============================================================
-- ÉTAPE 1 : TABLE MOS SIMPLIFIÉE - TOUS LES POLYGONES
-- ============================================================

DROP TABLE IF EXISTS visufoncier.mos_foncier_2024_geomsimplif CASCADE;

CREATE TABLE visufoncier.mos_foncier_2024_geomsimplif AS
SELECT
    id_mos_2024,
    id_mos_2021,
    code_insee_2024,
    nom_commune_2024,
    code4_2024,
    lib4_2024,
    regroup_2024,
    num_parc_2024,
    tex_2024,
    section_2024,
    subdi_2024,
    surface_m2_2024,
    code_insee_2021,
    nom_commune_2021,
    code4_2021,
    lib4_2021,
    regroup_2021,
    surface_m2_2021,
    code4_2011,
    lib4_2011,
    regroup_2011,
    tx_zic_2021,
    subdiv_2021,
    remarque11,
    remarque21,
    perimetre_2021,
    tx_zic_2024,
    scot,
    sraddet,
    correcteur,
    cons_enaf,
    remarque_2024,
    perimetre_2024,
    typeact_2024,
    dc_mos,
    codgeo_2025,
    libgeo_2025,
    code_epci_2025,
    lib_epci_2025,
    updated,
    type_conso_2011,
    type_conso_2021,
    type_conso_2024,
    ST_Multi(
        ST_SimplifyPreserveTopology(
            ST_SnapToGrid(
                ST_MakeValid(ST_Transform(geom, 2154))
            , 0.01)
        , 0.5)
    )                 AS geom
FROM visufoncier.mos_foncier_2024
WHERE geom IS NOT NULL;

ALTER TABLE visufoncier.mos_foncier_2024_geomsimplif
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154);

SELECT UpdateGeometrySRID('visufoncier', 'mos_foncier_2024_geomsimplif', 'geom', 2154);
SELECT Populate_Geometry_Columns('visufoncier.mos_foncier_2024_geomsimplif'::regclass);

CREATE INDEX idx_mos_simplif_id    ON visufoncier.mos_foncier_2024_geomsimplif USING btree (id_mos_2024);
CREATE INDEX idx_mos_simplif_insee ON visufoncier.mos_foncier_2024_geomsimplif USING btree (code_insee_2024);
CREATE INDEX idx_mos_simplif_geom  ON visufoncier.mos_foncier_2024_geomsimplif USING gist  (geom);

COMMENT ON TABLE visufoncier.mos_foncier_2024_geomsimplif IS
'MOS 2024 reprojeté en Lambert 93 (2154), géométries simplifiées (SnapToGrid 1cm + Simplify 50cm), converties en MultiPolygon. Table propre — ne pas modifier.';

SELECT COUNT(*) AS nb_polygones FROM visufoncier.mos_foncier_2024_geomsimplif;


-- ============================================================
-- ÉTAPE 1b : ENRICHISSEMENT GÉOGRAPHIQUE
-- ============================================================

ALTER TABLE visufoncier.mos_foncier_2024_geomsimplif
    ADD COLUMN IF NOT EXISTS siren_epci      VARCHAR,
    ADD COLUMN IF NOT EXISTS insee_dep       VARCHAR,
    ADD COLUMN IF NOT EXISTS insee_reg       VARCHAR,
    ADD COLUMN IF NOT EXISTS nom_epci        VARCHAR,
    ADD COLUMN IF NOT EXISTS nom_scot        VARCHAR,
    ADD COLUMN IF NOT EXISTS nom_departement VARCHAR;

UPDATE visufoncier.mos_foncier_2024_geomsimplif
SET nom_departement = CASE
    WHEN LEFT(code_insee_2024, 2) = '35' THEN 'Ille-et-Vilaine'
    WHEN LEFT(code_insee_2024, 2) = '22' THEN 'Côtes-d''Armor'
    WHEN LEFT(code_insee_2024, 2) = '56' THEN 'Morbihan'
    WHEN LEFT(code_insee_2024, 2) = '29' THEN 'Finistère'
END;

UPDATE visufoncier.mos_foncier_2024_geomsimplif t
SET
    siren_epci = c.siren_epci,
    insee_dep  = c.insee_dep,
    insee_reg  = c.insee_reg
FROM ign.express_commune c
WHERE t.code_insee_2024 = c.insee_com;

UPDATE visufoncier.mos_foncier_2024_geomsimplif t
SET nom_epci = e.nom_epci
FROM ign.express_epci e
WHERE t.siren_epci = e.code_epci;

UPDATE visufoncier.mos_foncier_2024_geomsimplif t
SET nom_scot = ff.scot
FROM visufoncier.ff_obs_artif_conso_com_2009_2024 ff
WHERE t.code_insee_2024 = ff.idcom;

CREATE INDEX idx_mos_simplif_dep  ON visufoncier.mos_foncier_2024_geomsimplif USING btree (nom_departement);
CREATE INDEX idx_mos_simplif_epci ON visufoncier.mos_foncier_2024_geomsimplif USING btree (nom_epci);
CREATE INDEX idx_mos_simplif_scot ON visufoncier.mos_foncier_2024_geomsimplif USING btree (nom_scot);

GRANT SELECT ON TABLE visufoncier.mos_foncier_2024_geomsimplif TO "app-visufoncier";
GRANT ALL    ON TABLE visufoncier.mos_foncier_2024_geomsimplif TO "margot.leborgne";
GRANT SELECT ON TABLE visufoncier.mos_foncier_2024_geomsimplif TO "www-data";

SELECT code_insee_2024, nom_commune_2024, nom_epci, nom_scot, nom_departement
FROM visufoncier.mos_foncier_2024_geomsimplif
LIMIT 10;


-- ============================================================
-- ÉTAPE 2 : TABLE DE RÉSULTATS TUP x MOS
-- ============================================================

DROP TABLE IF EXISTS visufoncier_private.v2_ff_tup_mos CASCADE;

CREATE TABLE visufoncier_private.v2_ff_tup_mos AS
SELECT
    id_mos_2024,
    NULL::integer AS nlogh25
FROM visufoncier.mos_foncier_2024_geomsimplif;

CREATE INDEX idx_v2_ff_tup_mos_id ON visufoncier_private.v2_ff_tup_mos USING btree (id_mos_2024);

COMMENT ON TABLE visufoncier_private.v2_ff_tup_mos IS
'Table de résultats du croisement MOS x FF TUP.
nlogh25 : FF 2025 utilisé pour les deux millésimes (correction décalage temporel orthophoto/déclaration fiscale)';

ALTER TABLE visufoncier_private.v2_ff_tup_mos
ADD COLUMN IF NOT EXISTS nlogh25 integer;
-- ============================================================
-- ÉTAPE 3 : ATTRIBUTION EXCLUSIVE TUP 2025 par département
-- ============================================================

-- Département 22
UPDATE visufoncier_private.v2_ff_tup_mos AS r
SET nlogh25 = t.nlogh
FROM (
    SELECT id_mos_2024, SUM(nlogh) AS nlogh
    FROM (
        SELECT DISTINCT ON (idtup) idtup, id_mos_2024, nlogh
        FROM (
            SELECT t.idtup, t.nlogh, m.id_mos_2024,
                ST_Area(ST_Intersection(m.geom, t.geom)) AS s_inter
            FROM visufoncier.mos_foncier_2024_geomsimplif m
            JOIN visufoncier_private.ffta_tup_2025_polygones_simple t
                ON ST_Intersects(m.geom, t.geom)
                AND m.code_insee_2024 = t.idcom
            WHERE t.geom IS NOT NULL
              AND m.code_insee_2024 LIKE '22%'
        ) sub
        WHERE s_inter > 0
        ORDER BY idtup, s_inter DESC
    ) attrib
    GROUP BY id_mos_2024
) AS t
WHERE r.id_mos_2024 = t.id_mos_2024;
COMMIT;

-- Département 29
UPDATE visufoncier_private.v2_ff_tup_mos AS r
SET nlogh25 = t.nlogh
FROM (
    SELECT id_mos_2024, SUM(nlogh) AS nlogh
    FROM (
        SELECT DISTINCT ON (idtup) idtup, id_mos_2024, nlogh
        FROM (
            SELECT t.idtup, t.nlogh, m.id_mos_2024,
                ST_Area(ST_Intersection(m.geom, t.geom)) AS s_inter
            FROM visufoncier.mos_foncier_2024_geomsimplif m
            JOIN visufoncier_private.ffta_tup_2025_polygones_simple t
                ON ST_Intersects(m.geom, t.geom)
                AND m.code_insee_2024 = t.idcom
            WHERE t.geom IS NOT NULL
              AND m.code_insee_2024 LIKE '29%'
        ) sub
        WHERE s_inter > 0
        ORDER BY idtup, s_inter DESC
    ) attrib
    GROUP BY id_mos_2024
) AS t
WHERE r.id_mos_2024 = t.id_mos_2024;
COMMIT;

-- Département 35
UPDATE visufoncier_private.v2_ff_tup_mos AS r
SET nlogh25 = t.nlogh
FROM (
    SELECT id_mos_2024, SUM(nlogh) AS nlogh
    FROM (
        SELECT DISTINCT ON (idtup) idtup, id_mos_2024, nlogh
        FROM (
            SELECT t.idtup, t.nlogh, m.id_mos_2024,
                ST_Area(ST_Intersection(m.geom, t.geom)) AS s_inter
            FROM visufoncier.mos_foncier_2024_geomsimplif m
            JOIN visufoncier_private.ffta_tup_2025_polygones_simple t
                ON ST_Intersects(m.geom, t.geom)
                AND m.code_insee_2024 = t.idcom
            WHERE t.geom IS NOT NULL
              AND m.code_insee_2024 LIKE '35%'
        ) sub
        WHERE s_inter > 0
        ORDER BY idtup, s_inter DESC
    ) attrib
    GROUP BY id_mos_2024
) AS t
WHERE r.id_mos_2024 = t.id_mos_2024;
COMMIT;

-- Département 56
UPDATE visufoncier_private.v2_ff_tup_mos AS r
SET nlogh25 = t.nlogh
FROM (
    SELECT id_mos_2024, SUM(nlogh) AS nlogh
    FROM (
        SELECT DISTINCT ON (idtup) idtup, id_mos_2024, nlogh
        FROM (
            SELECT t.idtup, t.nlogh, m.id_mos_2024,
                ST_Area(ST_Intersection(m.geom, t.geom)) AS s_inter
            FROM visufoncier.mos_foncier_2024_geomsimplif m
            JOIN visufoncier_private.ffta_tup_2025_polygones_simple t
                ON ST_Intersects(m.geom, t.geom)
                AND m.code_insee_2024 = t.idcom
            WHERE t.geom IS NOT NULL
              AND m.code_insee_2024 LIKE '56%'
        ) sub
        WHERE s_inter > 0
        ORDER BY idtup, s_inter DESC
    ) attrib
    GROUP BY id_mos_2024
) AS t
WHERE r.id_mos_2024 = t.id_mos_2024;
COMMIT;

-- Vérification globale
SELECT COUNT(*) AS nb_total, COUNT(nlogh25) AS nb_avec_logh, SUM(nlogh25) AS total_logh
FROM visufoncier_private.v2_ff_tup_mos;

GRANT SELECT ON TABLE visufoncier_private.v2_ff_tup_mos TO "app-visufoncier";
GRANT ALL    ON TABLE visufoncier_private.v2_ff_tup_mos TO "margot.leborgne";
GRANT SELECT ON TABLE visufoncier_private.v2_ff_tup_mos TO "www-data";


-- ============================================================
-- ÉTAPE 4 : VUE MATÉRIALISÉE DENSITÉ LOGEMENT PAR COMMUNE
-- nlogh21 et nlogh24 alimentés tous les deux par nlogh25
-- ============================================================
DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_ff_mos_tup_com_view CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_ff_mos_tup_com_view
TABLESPACE pg_default
AS
SELECT
    m.id_mos_2024,
    m.code_insee_2024       AS insee_com,
    m.nom_commune_2024      AS nom_commune,
    m.nom_epci,
    m.nom_scot,
    m.nom_departement,
    m.insee_dep,
    m.insee_reg,
    p.annee_debut,
    p.annee_fin,
    SUM(CASE
        WHEN p.annee_debut = '2011-01-01'::TIMESTAMP AND p.annee_fin = '2021-01-01'::TIMESTAMP
         AND m.code4_2021 IN ('1112','1113','1413','1222')
         AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                              '3251','3261','3311','3321',
                              '5121','5131','5231','5232','5233','5234')
        THEN COALESCE(r.nlogh25, 0)
        WHEN p.annee_debut = '2021-01-01'::TIMESTAMP AND p.annee_fin = '2024-01-01'::TIMESTAMP
         AND m.code4_2024 IN ('1112','1113','1413','1222')
         AND m.code4_2021 IN ('1131','1311','1334','1423','2121','2511',
                              '3251','3261','3311','3321',
                              '5121','5131','5231','5232','5233','5234')
        THEN COALESCE(r.nlogh25, 0)
        WHEN p.annee_debut = '2011-01-01'::TIMESTAMP AND p.annee_fin = '2024-01-01'::TIMESTAMP
         AND m.code4_2024 IN ('1112','1113','1413','1222')
         AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                              '3251','3261','3311','3321',
                              '5121','5131','5231','5232','5233','5234')
        THEN COALESCE(r.nlogh25, 0)
        ELSE 0
    END)                                                        AS total_nlogh,

    ROUND(SUM(CASE
        WHEN p.annee_debut = '2011-01-01'::TIMESTAMP AND p.annee_fin = '2021-01-01'::TIMESTAMP
         AND m.code4_2021 IN ('1112','1113','1413','1222')
         AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                              '3251','3261','3311','3321',
                              '5121','5131','5231','5232','5233','5234')
        THEN m.surface_m2_2024 / 10000.0
        WHEN p.annee_debut = '2021-01-01'::TIMESTAMP AND p.annee_fin = '2024-01-01'::TIMESTAMP
         AND m.code4_2024 IN ('1112','1113','1413','1222')
         AND m.code4_2021 IN ('1131','1311','1334','1423','2121','2511',
                              '3251','3261','3311','3321',
                              '5121','5131','5231','5232','5233','5234')
        THEN m.surface_m2_2024 / 10000.0
        WHEN p.annee_debut = '2011-01-01'::TIMESTAMP AND p.annee_fin = '2024-01-01'::TIMESTAMP
         AND m.code4_2024 IN ('1112','1113','1413','1222')
         AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                              '3251','3261','3311','3321',
                              '5121','5131','5231','5232','5233','5234')
        THEN m.surface_m2_2024 / 10000.0
        ELSE 0
    END)::numeric, 2)                                           AS surf_hab_ha,

    ROUND(
        SUM(CASE
            WHEN p.annee_debut = '2011-01-01'::TIMESTAMP AND p.annee_fin = '2021-01-01'::TIMESTAMP
             AND m.code4_2021 IN ('1112','1113','1413','1222')
             AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                                  '3251','3261','3311','3321',
                                  '5121','5131','5231','5232','5233','5234')
            THEN COALESCE(r.nlogh25, 0)
            WHEN p.annee_debut = '2021-01-01'::TIMESTAMP AND p.annee_fin = '2024-01-01'::TIMESTAMP
             AND m.code4_2024 IN ('1112','1113','1413','1222')
             AND m.code4_2021 IN ('1131','1311','1334','1423','2121','2511',
                                  '3251','3261','3311','3321',
                                  '5121','5131','5231','5232','5233','5234')
            THEN COALESCE(r.nlogh25, 0)
            WHEN p.annee_debut = '2011-01-01'::TIMESTAMP AND p.annee_fin = '2024-01-01'::TIMESTAMP
             AND m.code4_2024 IN ('1112','1113','1413','1222')
             AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                                  '3251','3261','3311','3321',
                                  '5121','5131','5231','5232','5233','5234')
            THEN COALESCE(r.nlogh25, 0)
            ELSE 0
        END)::numeric
        / NULLIF(SUM(CASE
            WHEN p.annee_debut = '2011-01-01'::TIMESTAMP AND p.annee_fin = '2021-01-01'::TIMESTAMP
             AND m.code4_2021 IN ('1112','1113','1413','1222')
             AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                                  '3251','3261','3311','3321',
                                  '5121','5131','5231','5232','5233','5234')
            THEN m.surface_m2_2024 / 10000.0
            WHEN p.annee_debut = '2021-01-01'::TIMESTAMP AND p.annee_fin = '2024-01-01'::TIMESTAMP
             AND m.code4_2024 IN ('1112','1113','1413','1222')
             AND m.code4_2021 IN ('1131','1311','1334','1423','2121','2511',
                                  '3251','3261','3311','3321',
                                  '5121','5131','5231','5232','5233','5234')
            THEN m.surface_m2_2024 / 10000.0
            WHEN p.annee_debut = '2011-01-01'::TIMESTAMP AND p.annee_fin = '2024-01-01'::TIMESTAMP
             AND m.code4_2024 IN ('1112','1113','1413','1222')
             AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                                  '3251','3261','3311','3321',
                                  '5121','5131','5231','5232','5233','5234')
            THEN m.surface_m2_2024 / 10000.0
            ELSE NULL
        END)::numeric, 0)
    , 2)                                                        AS densite_logh

FROM visufoncier.mos_foncier_2024_geomsimplif m
LEFT JOIN visufoncier_private.v2_ff_tup_mos r USING (id_mos_2024)
CROSS JOIN (
    VALUES
        ('2011-01-01 00:00:00'::TIMESTAMP, '2021-01-01 00:00:00'::TIMESTAMP),
        ('2021-01-01 00:00:00'::TIMESTAMP, '2024-01-01 00:00:00'::TIMESTAMP),
        ('2011-01-01 00:00:00'::TIMESTAMP, '2024-01-01 00:00:00'::TIMESTAMP)
) AS p(annee_debut, annee_fin)
WHERE
    (m.code4_2021 IN ('1112','1113','1413','1222')
     AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                          '3251','3261','3311','3321',
                          '5121','5131','5231','5232','5233','5234'))
    OR
    (m.code4_2024 IN ('1112','1113','1413','1222')
     AND m.code4_2021 IN ('1131','1311','1334','1423','2121','2511',
                          '3251','3261','3311','3321',
                          '5121','5131','5231','5232','5233','5234'))
    OR
    (m.code4_2024 IN ('1112','1113','1413','1222')
     AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                          '3251','3261','3311','3321',
                          '5121','5131','5231','5232','5233','5234'))
GROUP BY m.id_mos_2024, m.code_insee_2024, m.nom_commune_2024, m.nom_epci,
         m.nom_scot, m.nom_departement, m.insee_dep, m.insee_reg,
         p.annee_debut, p.annee_fin
WITH DATA;

CREATE INDEX idx_v2_ff_tup_com_id     ON visufoncier.v2_ff_mos_tup_com_view USING btree (id_mos_2024);
CREATE INDEX idx_v2_ff_tup_com_insee  ON visufoncier.v2_ff_mos_tup_com_view USING btree (insee_com);
CREATE INDEX idx_v2_ff_tup_com_annees ON visufoncier.v2_ff_mos_tup_com_view USING btree (annee_debut, annee_fin);
CREATE INDEX idx_v2_ff_tup_com_epci   ON visufoncier.v2_ff_mos_tup_com_view USING btree (nom_epci);
CREATE INDEX idx_v2_ff_tup_com_scot   ON visufoncier.v2_ff_mos_tup_com_view USING btree (nom_scot);
CREATE INDEX idx_v2_ff_tup_com_dep    ON visufoncier.v2_ff_mos_tup_com_view USING btree (nom_departement);

GRANT SELECT ON visufoncier.v2_ff_mos_tup_com_view TO "app-visufoncier";
GRANT ALL    ON visufoncier.v2_ff_mos_tup_com_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_ff_mos_tup_com_view TO "www-data";

COMMENT ON MATERIALIZED VIEW visufoncier.v2_ff_mos_tup_com_view IS
'Densité de logements par polygone MOS et par période sur les flux de consommation ENAF → habitat/jardin/voirie desserte.
Attribution exclusive : chaque TUP attribué au polygone MOS avec la plus grande intersection.
Codes destination : 1112, 1113 (habitat), 1413 (jardin de particulier), 1222 (voie desserte habitat).
Source logements : FF 2025 (nlogh25) — correction du décalage temporel orthophoto/déclaration fiscale.
3 périodes : 2011→2021, 2021→2024, 2011→2024.';




--Verif pour qgis sur une commune 
DROP TABLE IF EXISTS visufoncier.verif_concornet_v2_final CASCADE;

CREATE TABLE visufoncier.verif_concornet_v2_final AS
SELECT
    m.code_insee_2024       AS insee_com,
    m.nom_commune_2024      AS nom_commune,
    m.nom_epci,
    m.nom_scot,
    m.nom_departement,
    m.insee_dep,
    m.insee_reg,
    p.annee_debut,
    p.annee_fin,
    m.code4_2011,
    m.code4_2021,
    m.code4_2024,
    r.nlogh25,
    ROUND((m.surface_m2_2024 / 10000.0)::numeric, 2) AS surf_hab_ha,
    m.geom
FROM visufoncier.mos_foncier_2024_geomsimplif m
LEFT JOIN visufoncier_private.v2_ff_tup_mos r USING (id_mos_2024)
CROSS JOIN (
    VALUES (2011, 2021), (2021, 2024), (2011, 2024)
) AS p(annee_debut, annee_fin)
WHERE m.code_insee_2024 = '56043'
  AND (
    (m.code4_2021 IN ('1112','1113','1413','1222')
     AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                          '3251','3261','3311','3321',
                          '5121','5131','5231','5232','5233','5234'))
    OR
    (m.code4_2024 IN ('1112','1113','1413','1222')
     AND m.code4_2021 IN ('1131','1311','1334','1423','2121','2511',
                          '3251','3261','3311','3321',
                          '5121','5131','5231','5232','5233','5234'))
    OR
    (m.code4_2024 IN ('1112','1113','1413','1222')
     AND m.code4_2011 IN ('1131','1311','1334','1423','2121','2511',
                          '3251','3261','3311','3321',
                          '5121','5131','5231','5232','5233','5234'))
  );

CREATE INDEX idx_verif_concornet_v2_final_geom 
ON visufoncier.verif_concornet_v2_final USING gist (geom);