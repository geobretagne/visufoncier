
------------------------------------------------------------------------------------------------------------------------------
--Création des vues matérialisées -- données reliées au tableau de bord superset 
-------------------------------------------------------------------------------------------------------------------------------

REFRESH MATERIALIZED VIEW visufoncier.v2_densite_usage_view;
REFRESH MATERIALIZED VIEW visufoncier.v2_insee_evolution_view;
REFRESH MATERIALIZED VIEW visufoncier.v2_insee_temporel_view;
REFRESH MATERIALIZED VIEW visufoncier.v2_mos_agrege_com_conso_view;
REFRESH MATERIALIZED VIEW visufoncier.v2_mos_agrege_densification_view;
REFRESH MATERIALIZED VIEW visufoncier.v2_mos_agrege_enaf_nature_det_view;
REFRESH MATERIALIZED VIEW visufoncier.v2_mos_enaf_view;
REFRESH MATERIALIZED VIEW visufoncier.v2_mos_flux;
REFRESH MATERIALIZED VIEW visufoncier.v2_mos_flux_com;
REFRESH MATERIALIZED VIEW visufoncier.v2_v2_mos_flux_com_liengeo_view;
REFRESH MATERIALIZED VIEW visufoncier.v2_mos_foncier_agrege_gpu_view;


--Pour recreer les vues (si on veut les modifier), repartir de ces syntaxes en les adaptant : 

--VUE LA PLUS IMPORTANTE : CELLE POUR LES FILTRES GEO DU TDB SUPERSET
DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_flux_com_liengeo_view CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_flux_com_liengeo_view AS
WITH aggregated_geom AS (
    -- COMMUNES (avec leurs vraies périodes, pas de CROSS JOIN !)
    SELECT 
        f.insee_com,
        f.nom_commune,
        f.nom_epci,
        f.nom_scot,
        'Communes'::text AS type_territoire,
        f.nom_commune AS territoire,
        f.nom_departement,
        f.annee_debut,
        f.annee_fin,
        EXTRACT(YEAR FROM f.annee_debut)::TEXT || '-' || EXTRACT(YEAR FROM f.annee_fin)::TEXT as periode,
        st_centroid(c.geom) AS centroid_geom,
        14 AS z
    FROM visufoncier.v2_mos_flux_com f
    LEFT JOIN ign.express_commune c ON f.insee_com = c.insee_com
    
    UNION ALL
    
    -- EPCI
    SELECT 
        NULL, NULL,
        f.nom_epci,
        MAX(f.nom_scot) as nom_scot,
        'EPCI'::text,
        f.nom_epci,
        MAX(f.nom_departement),
        f.annee_debut,
        f.annee_fin,
        EXTRACT(YEAR FROM f.annee_debut)::TEXT || '-' || EXTRACT(YEAR FROM f.annee_fin)::TEXT,
        st_centroid(st_collect(c.geom)),
        11
    FROM visufoncier.v2_mos_flux_com f
    LEFT JOIN ign.express_commune c ON f.insee_com = c.insee_com
    GROUP BY f.nom_epci, f.annee_debut, f.annee_fin
    
    UNION ALL
    
    -- SCOT
    SELECT 
        NULL, NULL, NULL,
        f.nom_scot,
        'SCOT'::text,
        f.nom_scot,
        MAX(f.nom_departement),
        f.annee_debut,
        f.annee_fin,
        EXTRACT(YEAR FROM f.annee_debut)::TEXT || '-' || EXTRACT(YEAR FROM f.annee_fin)::TEXT,
        st_centroid(st_collect(c.geom)),
        11
    FROM visufoncier.v2_mos_flux_com f
    LEFT JOIN ign.express_commune c ON f.insee_com = c.insee_com
    GROUP BY f.nom_scot, f.annee_debut, f.annee_fin
    
    UNION ALL
    
    -- DÉPARTEMENT
    SELECT 
        NULL, NULL, NULL, NULL,
        'Département'::text,
        f.nom_departement,
        f.nom_departement,
        f.annee_debut,
        f.annee_fin,
        EXTRACT(YEAR FROM f.annee_debut)::TEXT || '-' || EXTRACT(YEAR FROM f.annee_fin)::TEXT,
        st_centroid(st_collect(c.geom)),
        12
    FROM visufoncier.v2_mos_flux_com f
    LEFT JOIN ign.express_commune c ON f.insee_com = c.insee_com
    WHERE LEFT(f.insee_com, 2) IN ('35', '22', '56', '29')
    GROUP BY f.nom_departement, f.annee_debut, f.annee_fin
    
    UNION ALL
    
    -- RÉGION
    SELECT 
        NULL, NULL, NULL, NULL,
        'Région'::text,
        'Bretagne'::character varying,
        NULL,
        annee_debut,
        annee_fin,
        EXTRACT(YEAR FROM annee_debut)::TEXT || '-' || EXTRACT(YEAR FROM annee_fin)::TEXT,
        NULL::geometry,
        8
    FROM (SELECT DISTINCT annee_debut, annee_fin FROM visufoncier.v2_mos_flux_com) p
)
SELECT 
    insee_com, nom_commune, nom_epci, nom_scot, type_territoire, territoire, nom_departement,
    annee_debut, annee_fin, periode,
    round(st_x(st_transform(centroid_geom, 3857))::numeric, 4) AS x,
    round(st_y(st_transform(centroid_geom, 3857))::numeric, 4) AS y,
    z::numeric AS z
FROM aggregated_geom;

GRANT SELECT ON visufoncier.v2_mos_flux_com_liengeo_view TO "app-visufoncier";
GRANT ALL ON visufoncier.v2_mos_flux_com_liengeo_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_mos_flux_com_liengeo_view TO "www-data";

COMMENT ON MATERIALIZED VIEW visufoncier.v2_mos_flux_com_liengeo_view IS
'Filtres géographiques avec coordonnées centroïdes. Une ligne par territoire ET par période réelle (pas de CROSS JOIN).';


--Verif nombre de com / remarque : j'ai 1202 code insee mais 1196 communes normal y'a des doublons entre les départements de nom de commune...
La Chapelle-Neuve	2	22037, 56039
Le Faouët	2	22057, 56057
Plouhinec	2	29197, 56169
Saint-Armel	2	35250, 56205
Saint-Servais	2	22328, 29264
Tréméven	2	22370, 29297

------------------------------------------------------------------------------------------------------------------------------
--VUE TEMPORELLE SIMPLIFIÉE graph 501 502 503
------------------------------------------------------------------------------------------------------------------------------

DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_insee_temporel_view;

CREATE MATERIALIZED VIEW visufoncier.v2_insee_temporel_view
TABLESPACE pg_default
AS SELECT i.insee_com,
    ma.nom_commune,
    c.siren_epci,
    e.nom_epci,
    c.insee_dep,
        CASE c.insee_dep
            WHEN '22'::text THEN 'Côtes-d''Armor'::text
            WHEN '29'::text THEN 'Finistère'::text
            WHEN '35'::text THEN 'Ille-et-Vilaine'::text
            WHEN '56'::text THEN 'Morbihan'::text
            ELSE NULL::text
        END AS nom_departement,
    tc.nom_scot AS nom_scot,
    m.annee_valeur,
    make_timestamp(m.annee_valeur, 1, 1, 0, 0, 0::double precision) AS annee,
        CASE m.annee_valeur
            WHEN 2011 THEN i.pnum2011
            WHEN 2012 THEN i.pnum2012
            WHEN 2013 THEN i.pnum2013
            WHEN 2014 THEN i.pnum2014
            WHEN 2015 THEN i.pnum2015
            WHEN 2016 THEN i.pnum2016
            WHEN 2017 THEN i.pnum2017
            WHEN 2018 THEN i.pnum2018
            WHEN 2019 THEN i.pnum2019
            WHEN 2020 THEN i.pnum2020
            WHEN 2021 THEN i.pnum2021
            WHEN 2022 THEN i.pnum2022
            WHEN 2023 THEN i.pnum2023
            ELSE NULL::numeric
        END AS population,
        CASE m.annee_valeur
            WHEN 2011 THEN i.p11_emplt
            WHEN 2017 THEN i.p17_emplt
            WHEN 2018 THEN i.p18_emplt
            WHEN 2020 THEN i.p20_emplt
            WHEN 2022 THEN i.p22_emplt
            ELSE NULL::numeric
        END AS emploi,
        CASE m.annee_valeur
            WHEN 2011 THEN i.c11_men
            WHEN 2017 THEN i.c17_men
            WHEN 2018 THEN i.c18_men
            WHEN 2019 THEN i.c19_men
            WHEN 2020 THEN i.c20_men
            WHEN 2022 THEN i.c22_men
            ELSE NULL::numeric
        END AS menages
   FROM visufoncier.insee_consolide i
     CROSS JOIN ( SELECT unnest(ARRAY[2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023]) AS annee_valeur) m
     LEFT JOIN ign.express_commune c ON i.insee_com = c.insee_com::text
     LEFT JOIN ign.express_epci e ON c.siren_epci::text = e.code_epci::text
     LEFT JOIN ign.table_correspondance tc ON i.insee_com = tc.code_insee
     LEFT JOIN (SELECT DISTINCT ON (insee_com) insee_com, nom_commune 
                FROM visufoncier.v2_mos_agrege) ma ON i.insee_com = ma.insee_com
WITH DATA;

CREATE INDEX idx_insee_temp_annee ON visufoncier.v2_insee_temporel_view USING btree (annee_valeur);
CREATE INDEX idx_insee_temp_com ON visufoncier.v2_insee_temporel_view USING btree (insee_com);
CREATE INDEX idx_insee_temp_epci ON visufoncier.v2_insee_temporel_view USING btree (nom_epci);




GRANT SELECT ON visufoncier.v2_insee_temporel_view TO "app-visufoncier";
GRANT ALL ON visufoncier.v2_insee_temporel_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_insee_temporel_view TO "www-data";


------------------------------------------------------------------------------------------------------------------------------
-- VUE : FLUX DE CONSOMMATION PAR NATURE (toutes périodes) graph 493 494 495 496
------------------------------------------------------------------------------------------------------------------------------

DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_agrege_com_conso_view CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_agrege_com_conso_view AS
WITH
-- État CONSO/ENAF au début et fin
etat_par_periode AS (
    SELECT 
        f.insee_com,
        f.annee_debut,
        f.annee_fin,
        MAX(CASE WHEN ed_debut.enaf_conso = 'conso' THEN ed_debut.surface_ha END) as surf_conso_debut,
        MAX(CASE WHEN ed_fin.enaf_conso = 'conso' THEN ed_fin.surface_ha END) as surf_conso_fin,
        MAX(CASE WHEN ed_debut.enaf_conso = 'enaf' THEN ed_debut.surface_ha END) as surf_enaf_debut,
        MAX(CASE WHEN ed_fin.enaf_conso = 'enaf' THEN ed_fin.surface_ha END) as surf_enaf_fin
    FROM (SELECT DISTINCT insee_com, annee_debut, annee_fin FROM visufoncier.v2_mos_flux) f
    LEFT JOIN (
        SELECT insee_com, annee, enaf_conso, ROUND(SUM(surface_ha)::numeric, 2) as surface_ha
        FROM visufoncier.v2_mos_agrege
        GROUP BY insee_com, annee, enaf_conso
    ) ed_debut ON f.insee_com = ed_debut.insee_com AND f.annee_debut = ed_debut.annee
    LEFT JOIN (
        SELECT insee_com, annee, enaf_conso, ROUND(SUM(surface_ha)::numeric, 2) as surface_ha
        FROM visufoncier.v2_mos_agrege
        GROUP BY insee_com, annee, enaf_conso
    ) ed_fin ON f.insee_com = ed_fin.insee_com AND f.annee_fin = ed_fin.annee
    GROUP BY f.insee_com, f.annee_debut, f.annee_fin
)

SELECT 
    f.insee_com,
    f.nom_commune,
    f.nom_epci,
    f.insee_dep,
    f.nom_scot,
    f.nom_departement,
    f.annee_debut,
    f.annee_fin ,
    -- Surface consommée (flux)
    ROUND(SUM(f.surface_ha)::numeric, 2) as total_surface_calc_ha,
    -- Nombre de polygones
    COUNT(*) as nb_polygones,
    -- États début/fin
    MAX(ep.surf_conso_debut) as surf_conso_debut,
    MAX(ep.surf_conso_fin) as surf_conso_fin,
    MAX(ep.surf_enaf_debut) as surf_enaf_debut,
    MAX(ep.surf_enaf_fin) as surf_enaf_fin
FROM visufoncier.v2_mos_flux f
LEFT JOIN etat_par_periode ep 
    ON f.insee_com = ep.insee_com 
    AND f.annee_debut = ep.annee_debut 
    AND f.annee_fin = ep.annee_fin
WHERE f.flux_conso = 1
GROUP BY 
    f.insee_com, f.nom_commune, f.nom_epci, f.insee_dep, 
    f.nom_scot, f.nom_departement, f.annee_debut, f.annee_fin;

-- Index
CREATE INDEX idx_v2_conso_view_insee ON visufoncier.v2_mos_agrege_com_conso_view (insee_com);
CREATE INDEX idx_v2_conso_view_annees ON visufoncier.v2_mos_agrege_com_conso_view (annee_debut, annee_fin);

-- Droits
GRANT SELECT ON visufoncier.v2_mos_agrege_com_conso_view TO "app-visufoncier";
GRANT ALL ON visufoncier.v2_mos_agrege_com_conso_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_mos_agrege_com_conso_view TO "www-data";

COMMENT ON MATERIALIZED VIEW visufoncier.v2_mos_agrege_com_conso_view IS
'Flux de consommation par commune avec états CONSO/ENAF début et fin. Onglet Consommation Superset.';

-- =====================================================
-- VUE : FLUX CONSOMMATION PAR NATURE DE DESTINATION (v2) graph 491 492
-- =====================================================
DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_agrege_nature_det_view CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_agrege_nature_det_view AS
SELECT 
    f.nature_fin,
    f.nature_det_fin,
    m.code4 AS code4_fin,
    f.insee_com,
    f.nom_commune,
    f.nom_epci,
    f.nom_scot,
    f.nom_departement,
    f.annee_debut,
    f.annee_fin,
    ROUND(SUM(f.surface_ha)::numeric, 2) AS total_surface_ha
FROM visufoncier.v2_mos_flux f
LEFT JOIN visufoncier.v2_mos_agrege m
    ON f.groupe_id = m.groupe_id
    AND f.annee_fin = m.annee
WHERE f.flux_conso = 1
GROUP BY 
    f.nature_fin, f.nature_det_fin,
    m.code4,
    f.insee_com, f.nom_commune, 
    f.nom_epci, f.nom_scot, f.nom_departement, 
    f.annee_debut, f.annee_fin;

CREATE INDEX idx_v2_nature_det_nature  ON visufoncier.v2_mos_agrege_nature_det_view (nature_fin, nature_det_fin);
CREATE INDEX idx_v2_nature_det_code4   ON visufoncier.v2_mos_agrege_nature_det_view (code4_fin);
CREATE INDEX idx_v2_nature_det_commune ON visufoncier.v2_mos_agrege_nature_det_view (nom_commune);
CREATE INDEX idx_v2_nature_det_annees  ON visufoncier.v2_mos_agrege_nature_det_view (annee_debut, annee_fin);

GRANT SELECT ON visufoncier.v2_mos_agrege_nature_det_view TO "app-visufoncier";
GRANT ALL    ON visufoncier.v2_mos_agrege_nature_det_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_mos_agrege_nature_det_view TO "www-data";

COMMENT ON MATERIALIZED VIEW visufoncier.v2_mos_agrege_nature_det_view IS
'Surfaces consommées par nature détaillée et code4, pour filtrage densification dans Superset.';

-- =====================================================
-- VUES : STOCK --Densification graph 497 499 500
-- =====================================================


DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_agrege_densification_view CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_agrege_densification_view AS
SELECT 
    m_fin.code4 AS code4_fin,
    m_fin.nature AS nature_fin,
    m_fin.nature_det AS nature_det_fin,
    f.insee_com,
    f.nom_commune,
    f.nom_epci,
    f.nom_scot,
    f.nom_departement,
    f.annee_debut,
    f.annee_fin,
    ROUND(SUM(f.surface_ha)::numeric, 2) AS total_surface_ha
FROM visufoncier.v2_mos_flux f
JOIN visufoncier.v2_mos_agrege m_fin
    ON f.groupe_id = m_fin.groupe_id
    AND f.annee_fin = m_fin.annee
GROUP BY 
    m_fin.code4, m_fin.nature, m_fin.nature_det,
    f.insee_com, f.nom_commune,
    f.nom_epci, f.nom_scot, f.nom_departement,
    f.annee_debut, f.annee_fin
ORDER BY total_surface_ha DESC;

CREATE INDEX idx_v2_densif_code4   ON visufoncier.v2_mos_agrege_densification_view (code4_fin);
CREATE INDEX idx_v2_densif_nature  ON visufoncier.v2_mos_agrege_densification_view (nature_fin, nature_det_fin);
CREATE INDEX idx_v2_densif_commune ON visufoncier.v2_mos_agrege_densification_view (nom_epci, nom_commune, nom_scot, nom_departement);
CREATE INDEX idx_v2_densif_annee   ON visufoncier.v2_mos_agrege_densification_view (annee_debut, annee_fin);

GRANT SELECT ON visufoncier.v2_mos_agrege_densification_view TO "app-visufoncier";
GRANT ALL    ON visufoncier.v2_mos_agrege_densification_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_mos_agrege_densification_view TO "www-data";

COMMENT ON MATERIALIZED VIEW visufoncier.v2_mos_agrege_densification_view IS
'Surfaces par code4_fin, nature_fin et nature_det_fin par commune et période. Filtrage sur les codes de densification à faire dans Superset.';

-- =====================================================
--nature détaillée stock enaf graph 498
-- =====================================================
DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_agrege_enaf_nature_det_view CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_agrege_enaf_nature_det_view AS
SELECT 
    m_fin.nature AS nature_fin,
    m_fin.nature_det AS nature_det_fin,
    m_fin.code4 AS code4_fin,
    f.insee_com,
    f.nom_commune,
    f.nom_epci,
    f.nom_scot,
    f.nom_departement,
    f.annee_debut,
    f.annee_fin,
    ROUND(SUM(f.surface_ha)::numeric, 2) AS total_surface_ha
FROM visufoncier.v2_mos_flux f
JOIN visufoncier.v2_mos_agrege m_fin
    ON f.groupe_id = m_fin.groupe_id
    AND f.annee_fin = m_fin.annee
WHERE f.enaf_conso_fin = 'enaf'
GROUP BY 
    m_fin.nature, m_fin.nature_det, m_fin.code4,
    f.insee_com, f.nom_commune,
    f.nom_epci, f.nom_scot, f.nom_departement,
    f.annee_debut, f.annee_fin
ORDER BY total_surface_ha DESC;

CREATE INDEX idx_v2_enaf_nature_det  ON visufoncier.v2_mos_agrege_enaf_nature_det_view (nature_fin, nature_det_fin);
CREATE INDEX idx_v2_enaf_code4       ON visufoncier.v2_mos_agrege_enaf_nature_det_view (code4_fin);
CREATE INDEX idx_v2_enaf_commune     ON visufoncier.v2_mos_agrege_enaf_nature_det_view (nom_epci, nom_commune, nom_scot, nom_departement);
CREATE INDEX idx_v2_enaf_annee       ON visufoncier.v2_mos_agrege_enaf_nature_det_view (annee_debut, annee_fin);

GRANT SELECT ON visufoncier.v2_mos_agrege_enaf_nature_det_view TO "app-visufoncier";
GRANT ALL    ON visufoncier.v2_mos_agrege_enaf_nature_det_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_mos_agrege_enaf_nature_det_view TO "www-data";

COMMENT ON MATERIALIZED VIEW visufoncier.v2_mos_agrege_enaf_nature_det_view IS
'Surfaces ENAF restantes en fin de période, détaillées par nature_det et code4. Filtrage complémentaire (ex: densification) à faire dans Superset.';

-- =====================================================
-- Version complète avec densité calculée graphique 504
-- =====================================================
DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_densite_usage_view CASCADE;

DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_densite_usage_view CASCADE;

CREATE MATERIALIZED VIEW visufoncier.v2_densite_usage_view AS
WITH base AS (
    SELECT 
        f.insee_com,
        f.nom_commune,
        f.nom_epci,
        f.nom_scot,
        f.nom_departement,
        f.insee_dep,
        f.annee_debut,
        f.annee_fin,
        EXTRACT(YEAR FROM f.annee_debut)::integer AS annee_debut_valeur,
        EXTRACT(YEAR FROM f.annee_fin)::integer AS annee_fin_valeur,
        SUM(CASE WHEN f.enaf_conso_fin = 'conso' THEN f.surface_ha ELSE 0 END)::numeric AS surf_conso_ha
    FROM visufoncier.v2_mos_flux f
    GROUP BY f.insee_com, f.nom_commune, f.nom_epci, f.nom_scot, 
             f.nom_departement, f.insee_dep, f.annee_debut, f.annee_fin
)
SELECT 
    b.*,
    CASE b.annee_fin_valeur
        WHEN 2021 THEN i.pnum2021
        WHEN 2024 THEN i.pnum2023
    END::numeric AS population,
    CASE b.annee_fin_valeur
        WHEN 2021 THEN i.p20_emplt
        WHEN 2024 THEN i.p22_emplt
    END::numeric AS emploi,
    CASE WHEN b.surf_conso_ha > 0 THEN
        ROUND((
            COALESCE(CASE b.annee_fin_valeur WHEN 2021 THEN i.pnum2021 WHEN 2024 THEN i.pnum2023 END, 0) +
            COALESCE(CASE b.annee_fin_valeur WHEN 2021 THEN i.p20_emplt WHEN 2024 THEN i.p22_emplt END, 0)
        )::numeric / b.surf_conso_ha, 2)
    END AS densite_usage
FROM base b
LEFT JOIN visufoncier.insee_consolide i ON b.insee_com = i.insee_com;

CREATE INDEX idx_densite_insee ON visufoncier.v2_densite_usage_view (insee_com);
CREATE INDEX idx_densite_annees ON visufoncier.v2_densite_usage_view (annee_debut_valeur, annee_fin_valeur);
CREATE INDEX idx_densite_epci ON visufoncier.v2_densite_usage_view (nom_epci);

GRANT SELECT ON visufoncier.v2_densite_usage_view TO "app-visufoncier";
GRANT ALL ON visufoncier.v2_densite_usage_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_densite_usage_view TO "www-data";

-- =====================================================
---Insee evolution graph 505 506
-- =====================================================
DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_insee_evolution_view;

CREATE MATERIALIZED VIEW visufoncier.v2_insee_evolution_view
TABLESPACE pg_default
AS WITH periodes AS (
         SELECT 2011 AS annee_debut,
            2021 AS annee_fin
        UNION ALL
         SELECT 2021,
            2024
        UNION ALL
         SELECT 2011,
            2024
        ), surfaces AS (
         SELECT v2_mos_agrege.insee_com,
            date_part('year'::text, v2_mos_agrege.annee)::integer AS annee_valeur,
            sum(
                CASE
                    WHEN v2_mos_agrege.enaf_conso = 'conso'::text THEN v2_mos_agrege.surface_ha
                    ELSE 0::double precision
                END)::numeric AS surf_conso_ha
           FROM visufoncier.v2_mos_agrege
          GROUP BY v2_mos_agrege.insee_com, (date_part('year'::text, v2_mos_agrege.annee)::integer)
        )
 SELECT i.insee_com,
    ma.nom_commune,
    c.siren_epci,
    e.nom_epci,
    c.insee_dep,
        CASE c.insee_dep
            WHEN '22'::text THEN 'Côtes-d''Armor'::text
            WHEN '29'::text THEN 'Finistère'::text
            WHEN '35'::text THEN 'Ille-et-Vilaine'::text
            WHEN '56'::text THEN 'Morbihan'::text
            ELSE NULL::text
        END AS nom_departement,
    tc.nom_scot AS nom_scot,
    make_timestamp(p.annee_debut, 1, 1, 0, 0, 0::double precision) AS annee_debut,
    make_timestamp(p.annee_fin, 1, 1, 0, 0, 0::double precision) AS annee_fin,
    p.annee_debut AS annee_debut_valeur,
    p.annee_fin AS annee_fin_valeur,
        CASE p.annee_debut
            WHEN 2011 THEN i.pnum2011
            WHEN 2021 THEN i.pnum2021
            ELSE NULL::numeric
        END AS pop_debut,
        CASE p.annee_fin
            WHEN 2021 THEN i.pnum2021
            WHEN 2024 THEN i.pnum2023
            ELSE NULL::numeric
        END AS pop_fin,
        CASE p.annee_fin
            WHEN 2021 THEN i.pnum2021
            WHEN 2024 THEN i.pnum2023
            ELSE NULL::numeric
        END -
        CASE p.annee_debut
            WHEN 2011 THEN i.pnum2011
            WHEN 2021 THEN i.pnum2021
            ELSE NULL::numeric
        END AS pop_diff,
        CASE
            WHEN
            CASE p.annee_debut
                WHEN 2011 THEN i.pnum2011
                WHEN 2021 THEN i.pnum2021
                ELSE NULL::numeric
            END > 0::numeric THEN round((
            CASE p.annee_fin
                WHEN 2021 THEN i.pnum2021
                WHEN 2024 THEN i.pnum2023
                ELSE NULL::numeric
            END -
            CASE p.annee_debut
                WHEN 2011 THEN i.pnum2011
                WHEN 2021 THEN i.pnum2021
                ELSE NULL::numeric
            END) /
            CASE p.annee_debut
                WHEN 2011 THEN i.pnum2011
                WHEN 2021 THEN i.pnum2021
                ELSE NULL::numeric
            END * 100::numeric, 1)
            ELSE NULL::numeric
        END AS pop_taux_evol,
        CASE p.annee_debut
            WHEN 2011 THEN i.p11_emplt
            WHEN 2021 THEN i.p20_emplt
            ELSE NULL::numeric
        END AS emploi_debut,
        CASE p.annee_fin
            WHEN 2021 THEN i.p20_emplt
            WHEN 2024 THEN i.p22_emplt
            ELSE NULL::numeric
        END AS emploi_fin,
        CASE p.annee_fin
            WHEN 2021 THEN i.p20_emplt
            WHEN 2024 THEN i.p22_emplt
            ELSE NULL::numeric
        END -
        CASE p.annee_debut
            WHEN 2011 THEN i.p11_emplt
            WHEN 2021 THEN i.p20_emplt
            ELSE NULL::numeric
        END AS emploi_diff,
        CASE
            WHEN
            CASE p.annee_debut
                WHEN 2011 THEN i.p11_emplt
                WHEN 2021 THEN i.p20_emplt
                ELSE NULL::numeric
            END > 0::numeric THEN round((
            CASE p.annee_fin
                WHEN 2021 THEN i.p20_emplt
                WHEN 2024 THEN i.p22_emplt
                ELSE NULL::numeric
            END -
            CASE p.annee_debut
                WHEN 2011 THEN i.p11_emplt
                WHEN 2021 THEN i.p20_emplt
                ELSE NULL::numeric
            END) /
            CASE p.annee_debut
                WHEN 2011 THEN i.p11_emplt
                WHEN 2021 THEN i.p20_emplt
                ELSE NULL::numeric
            END * 100::numeric, 1)
            ELSE NULL::numeric
        END AS emploi_taux_evol,
        CASE p.annee_debut
            WHEN 2011 THEN i.c11_men
            WHEN 2021 THEN i.c20_men
            ELSE NULL::numeric
        END AS menages_debut,
        CASE p.annee_fin
            WHEN 2021 THEN i.c20_men
            WHEN 2024 THEN i.c22_men
            ELSE NULL::numeric
        END AS menages_fin,
        CASE p.annee_fin
            WHEN 2021 THEN i.c20_men
            WHEN 2024 THEN i.c22_men
            ELSE NULL::numeric
        END -
        CASE p.annee_debut
            WHEN 2011 THEN i.c11_men
            WHEN 2021 THEN i.c20_men
            ELSE NULL::numeric
        END AS menages_diff,
        CASE
            WHEN
            CASE p.annee_debut
                WHEN 2011 THEN i.c11_men
                WHEN 2021 THEN i.c20_men
                ELSE NULL::numeric
            END > 0::numeric THEN round((
            CASE p.annee_fin
                WHEN 2021 THEN i.c20_men
                WHEN 2024 THEN i.c22_men
                ELSE NULL::numeric
            END -
            CASE p.annee_debut
                WHEN 2011 THEN i.c11_men
                WHEN 2021 THEN i.c20_men
                ELSE NULL::numeric
            END) /
            CASE p.annee_debut
                WHEN 2011 THEN i.c11_men
                WHEN 2021 THEN i.c20_men
                ELSE NULL::numeric
            END * 100::numeric, 1)
            ELSE NULL::numeric
        END AS menages_taux_evol,
    sd.surf_conso_ha AS surf_conso_debut,
    sf.surf_conso_ha AS surf_conso_fin,
        CASE
            WHEN sd.surf_conso_ha > 0::numeric THEN round((COALESCE(
            CASE p.annee_debut
                WHEN 2011 THEN i.pnum2011
                WHEN 2021 THEN i.pnum2021
                ELSE NULL::numeric
            END, 0::numeric) + COALESCE(
            CASE p.annee_debut
                WHEN 2011 THEN i.p11_emplt
                WHEN 2021 THEN i.p20_emplt
                ELSE NULL::numeric
            END, 0::numeric)) / sd.surf_conso_ha, 2)
            ELSE NULL::numeric
        END AS densite_debut,
        CASE
            WHEN sf.surf_conso_ha > 0::numeric THEN round((COALESCE(
            CASE p.annee_fin
                WHEN 2021 THEN i.pnum2021
                WHEN 2024 THEN i.pnum2023
                ELSE NULL::numeric
            END, 0::numeric) + COALESCE(
            CASE p.annee_fin
                WHEN 2021 THEN i.p20_emplt
                WHEN 2024 THEN i.p22_emplt
                ELSE NULL::numeric
            END, 0::numeric)) / sf.surf_conso_ha, 2)
            ELSE NULL::numeric
        END AS densite_fin,
        CASE
            WHEN sd.surf_conso_ha > 0::numeric AND sf.surf_conso_ha > 0::numeric THEN round((COALESCE(
            CASE p.annee_fin
                WHEN 2021 THEN i.pnum2021
                WHEN 2024 THEN i.pnum2023
                ELSE NULL::numeric
            END, 0::numeric) + COALESCE(
            CASE p.annee_fin
                WHEN 2021 THEN i.p20_emplt
                WHEN 2024 THEN i.p22_emplt
                ELSE NULL::numeric
            END, 0::numeric)) / sf.surf_conso_ha, 2) - round((COALESCE(
            CASE p.annee_debut
                WHEN 2011 THEN i.pnum2011
                WHEN 2021 THEN i.pnum2021
                ELSE NULL::numeric
            END, 0::numeric) + COALESCE(
            CASE p.annee_debut
                WHEN 2011 THEN i.p11_emplt
                WHEN 2021 THEN i.p20_emplt
                ELSE NULL::numeric
            END, 0::numeric)) / sd.surf_conso_ha, 2)
            ELSE NULL::numeric
        END AS densite_diff,
        CASE
            WHEN sd.surf_conso_ha > 0::numeric AND sf.surf_conso_ha > 0::numeric AND (COALESCE(
            CASE p.annee_debut
                WHEN 2011 THEN i.pnum2011
                WHEN 2021 THEN i.pnum2021
                ELSE NULL::numeric
            END, 0::numeric) + COALESCE(
            CASE p.annee_debut
                WHEN 2011 THEN i.p11_emplt
                WHEN 2021 THEN i.p20_emplt
                ELSE NULL::numeric
            END, 0::numeric)) > 0::numeric THEN round(((COALESCE(
            CASE p.annee_fin
                WHEN 2021 THEN i.pnum2021
                WHEN 2024 THEN i.pnum2023
                ELSE NULL::numeric
            END, 0::numeric) + COALESCE(
            CASE p.annee_fin
                WHEN 2021 THEN i.p20_emplt
                WHEN 2024 THEN i.p22_emplt
                ELSE NULL::numeric
            END, 0::numeric)) / sf.surf_conso_ha - (COALESCE(
            CASE p.annee_debut
                WHEN 2011 THEN i.pnum2011
                WHEN 2021 THEN i.pnum2021
                ELSE NULL::numeric
            END, 0::numeric) + COALESCE(
            CASE p.annee_debut
                WHEN 2011 THEN i.p11_emplt
                WHEN 2021 THEN i.p20_emplt
                ELSE NULL::numeric
            END, 0::numeric)) / sd.surf_conso_ha) / ((COALESCE(
            CASE p.annee_debut
                WHEN 2011 THEN i.pnum2011
                WHEN 2021 THEN i.pnum2021
                ELSE NULL::numeric
            END, 0::numeric) + COALESCE(
            CASE p.annee_debut
                WHEN 2011 THEN i.p11_emplt
                WHEN 2021 THEN i.p20_emplt
                ELSE NULL::numeric
            END, 0::numeric)) / sd.surf_conso_ha) * 100::numeric, 1)
            ELSE NULL::numeric
        END AS densite_taux_evol
   FROM visufoncier.insee_consolide i
     CROSS JOIN periodes p
     LEFT JOIN ign.express_commune c ON i.insee_com = c.insee_com::text
     LEFT JOIN ign.express_epci e ON c.siren_epci::text = e.code_epci::text
     LEFT JOIN ign.table_correspondance tc ON i.insee_com = tc.code_insee
     LEFT JOIN (SELECT DISTINCT ON (insee_com) insee_com, nom_commune 
                FROM visufoncier.v2_mos_agrege) ma ON i.insee_com = ma.insee_com
     LEFT JOIN surfaces sd ON i.insee_com = sd.insee_com AND sd.annee_valeur = p.annee_debut
     LEFT JOIN surfaces sf ON i.insee_com = sf.insee_com AND sf.annee_valeur = p.annee_fin
WITH DATA;

CREATE INDEX idx_insee_evol_annees ON visufoncier.v2_insee_evolution_view USING btree (annee_debut_valeur, annee_fin_valeur);
CREATE INDEX idx_insee_evol_com ON visufoncier.v2_insee_evolution_view USING btree (insee_com);
CREATE INDEX idx_insee_evol_epci ON visufoncier.v2_insee_evolution_view USING btree (nom_epci);

GRANT SELECT ON visufoncier.v2_insee_evolution_view TO "app-visufoncier";
GRANT ALL ON visufoncier.v2_insee_evolution_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_insee_evolution_view TO "www-data";


-- =====================================================
---MOS X GPU 
-- =====================================================
DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_foncier_agrege_gpu_view;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_foncier_agrege_gpu_view
TABLESPACE pg_default
AS WITH communes AS (
         SELECT DISTINCT c.insee_com,
            ma.nom_commune,
            c.siren_epci,
            e.nom_epci,
            c.insee_dep,
                CASE c.insee_dep
                    WHEN '22'::text THEN 'Côtes-d''Armor'::text
                    WHEN '29'::text THEN 'Finistère'::text
                    WHEN '35'::text THEN 'Ille-et-Vilaine'::text
                    WHEN '56'::text THEN 'Morbihan'::text
                    ELSE NULL::text
                END AS nom_departement,
            tc.nom_scot
           FROM ign.express_commune c
             LEFT JOIN ign.express_epci e ON c.siren_epci::text = e.code_epci::text
             LEFT JOIN ign.table_correspondance tc ON c.insee_com::text = tc.code_insee::text
             LEFT JOIN (SELECT DISTINCT ON (insee_com) insee_com, nom_commune 
                        FROM visufoncier.v2_mos_agrege) ma ON c.insee_com::text = ma.insee_com
          WHERE c.insee_dep::text = ANY (ARRAY['22'::character varying::text, '29'::character varying::text, '35'::character varying::text, '56'::character varying::text])
        ), calc AS (
         SELECT v2_gpu_mos_enaf_plu_plui.insee_com,
            COALESCE(st_area(st_union(v2_gpu_mos_enaf_plu_plui.geom)) / 10000.0::double precision, 0::double precision) AS surface_total,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui.typezone::text = 'U'::text THEN v2_gpu_mos_enaf_plu_plui.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_u,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui.typezone::text = 'AUc'::text THEN v2_gpu_mos_enaf_plu_plui.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_auc,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui.typezone::text = 'AUs'::text THEN v2_gpu_mos_enaf_plu_plui.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_aus
           FROM visufoncier.v2_gpu_mos_enaf_plu_plui
          GROUP BY v2_gpu_mos_enaf_plu_plui.insee_com
        ), secteurcc AS (
         SELECT v2_gpu_mos_enaf_cc.insee_com,
            COALESCE(sum(
                CASE
                    WHEN v2_gpu_mos_enaf_cc.typesect::text = '01'::text THEN st_area(v2_gpu_mos_enaf_cc.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_01,
            COALESCE(sum(
                CASE
                    WHEN v2_gpu_mos_enaf_cc.typesect::text = '02'::text THEN st_area(v2_gpu_mos_enaf_cc.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_02,
            COALESCE(sum(st_area(v2_gpu_mos_enaf_cc.geom) / 10000.0::double precision), 0::double precision) AS surface_secteurcc_total
           FROM visufoncier.v2_gpu_mos_enaf_cc
          GROUP BY v2_gpu_mos_enaf_cc.insee_com
        ), calc_ajust AS (
         SELECT v2_gpu_mos_enaf_plu_plui_ajust.insee_com,
            COALESCE(st_area(st_union(v2_gpu_mos_enaf_plu_plui_ajust.geom)) / 10000.0::double precision, 0::double precision) AS surface_total_ajust,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui_ajust.typezone::text = 'U'::text THEN v2_gpu_mos_enaf_plu_plui_ajust.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_u_ajust,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui_ajust.typezone::text = 'AUc'::text THEN v2_gpu_mos_enaf_plu_plui_ajust.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_auc_ajust,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui_ajust.typezone::text = 'AUs'::text THEN v2_gpu_mos_enaf_plu_plui_ajust.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_aus_ajust
           FROM visufoncier.v2_gpu_mos_enaf_plu_plui_ajust
          GROUP BY v2_gpu_mos_enaf_plu_plui_ajust.insee_com
        ), secteurcc_ajust AS (
         SELECT v2_gpu_mos_enaf_cc_ajust.insee_com,
            COALESCE(sum(
                CASE
                    WHEN v2_gpu_mos_enaf_cc_ajust.typesect::text = '01'::text THEN st_area(v2_gpu_mos_enaf_cc_ajust.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_01_ajust,
            COALESCE(sum(
                CASE
                    WHEN v2_gpu_mos_enaf_cc_ajust.typesect::text = '02'::text THEN st_area(v2_gpu_mos_enaf_cc_ajust.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_02_ajust,
            COALESCE(sum(st_area(v2_gpu_mos_enaf_cc_ajust.geom) / 10000.0::double precision), 0::double precision) AS surface_secteurcc_total_ajust
           FROM visufoncier.v2_gpu_mos_enaf_cc_ajust
          GROUP BY v2_gpu_mos_enaf_cc_ajust.insee_com
        )
 SELECT a.insee_com,
    a.nom_commune,
    a.nom_epci,
    a.nom_scot,
    a.insee_dep,
    a.nom_departement,
    COALESCE(calc.surface_total, 0::double precision) AS surface_total,
    COALESCE(calc.surface_u, 0::double precision) AS surface_u,
    COALESCE(calc.surface_auc, 0::double precision) AS surface_auc,
    COALESCE(calc.surface_aus, 0::double precision) AS surface_aus,
    COALESCE(secteurcc.surface_secteurcc_01, 0::double precision) AS surface_secteurcc_01,
    COALESCE(secteurcc.surface_secteurcc_02, 0::double precision) AS surface_secteurcc_02,
    COALESCE(secteurcc.surface_secteurcc_total, 0::double precision) AS surface_secteurcc_total,
    COALESCE(calc_ajust.surface_total_ajust, 0::double precision) AS surface_total_ajust,
    COALESCE(calc_ajust.surface_u_ajust, 0::double precision) AS surface_u_ajust,
    COALESCE(calc_ajust.surface_auc_ajust, 0::double precision) AS surface_auc_ajust,
    COALESCE(calc_ajust.surface_aus_ajust, 0::double precision) AS surface_aus_ajust,
    COALESCE(secteurcc_ajust.surface_secteurcc_01_ajust, 0::double precision) AS surface_secteurcc_01_ajust,
    COALESCE(secteurcc_ajust.surface_secteurcc_02_ajust, 0::double precision) AS surface_secteurcc_02_ajust,
    COALESCE(secteurcc_ajust.surface_secteurcc_total_ajust, 0::double precision) AS surface_secteurcc_total_ajust
   FROM communes a
     LEFT JOIN calc ON a.insee_com::text = calc.insee_com::text
     LEFT JOIN secteurcc ON a.insee_com::text = secteurcc.insee_com::text
     LEFT JOIN calc_ajust ON a.insee_com::text = calc_ajust.insee_com::text
     LEFT JOIN secteurcc_ajust ON a.insee_com::text = secteurcc_ajust.insee_com::text
WITH DATA;

CREATE INDEX idx_v2_gpu_epci ON visufoncier.v2_mos_foncier_agrege_gpu_view USING btree (nom_epci);
CREATE INDEX idx_v2_gpu_insee ON visufoncier.v2_mos_foncier_agrege_gpu_view USING btree (insee_com);
CREATE INDEX idx_v2_gpu_scot ON visufoncier.v2_mos_foncier_agrege_gpu_view USING btree (nom_scot);

GRANT SELECT ON visufoncier.v2_mos_foncier_agrege_gpu_view TO "app-visufoncier";
GRANT ALL ON visufoncier.v2_mos_foncier_agrege_gpu_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_mos_foncier_agrege_gpu_view TO "www-data";

COMMENT ON MATERIALIZED VIEW visufoncier.v2_mos_foncier_agrege_gpu_view IS
'Table du MOS ENAF 2024 croisée avec les données du GPU (PLU, PLUi et cartes communales). Reliée au tableau de bord Superset.'


--2021 

DROP MATERIALIZED VIEW IF EXISTS visufoncier.v2_mos_foncier_agrege_gpu_2021_view;

CREATE MATERIALIZED VIEW visufoncier.v2_mos_foncier_agrege_gpu_2021_view
TABLESPACE pg_default
AS WITH communes AS (
         SELECT DISTINCT c.insee_com,
            ma.nom_commune,
            c.siren_epci,
            e.nom_epci,
            c.insee_dep,
                CASE c.insee_dep
                    WHEN '22'::text THEN 'Côtes-d''Armor'::text
                    WHEN '29'::text THEN 'Finistère'::text
                    WHEN '35'::text THEN 'Ille-et-Vilaine'::text
                    WHEN '56'::text THEN 'Morbihan'::text
                    ELSE NULL::text
                END AS nom_departement,
            tc.nom_scot
           FROM ign.express_commune c
             LEFT JOIN ign.express_epci e ON c.siren_epci::text = e.code_epci::text
             LEFT JOIN ign.table_correspondance tc ON c.insee_com::text = tc.code_insee::text
             LEFT JOIN (SELECT DISTINCT ON (insee_com) insee_com, nom_commune 
                        FROM visufoncier.v2_mos_agrege) ma ON c.insee_com::text = ma.insee_com
          WHERE c.insee_dep::text = ANY (ARRAY['22'::character varying::text, '29'::character varying::text, '35'::character varying::text, '56'::character varying::text])
        ), calc AS (
         SELECT v2_gpu_mos_enaf_plu_plui_2021.insee_com,
            COALESCE(st_area(st_union(v2_gpu_mos_enaf_plu_plui_2021.geom)) / 10000.0::double precision, 0::double precision) AS surface_total,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui_2021.typezone::text = 'U'::text THEN v2_gpu_mos_enaf_plu_plui_2021.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_u,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui_2021.typezone::text = 'AUc'::text THEN v2_gpu_mos_enaf_plu_plui_2021.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_auc,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui_2021.typezone::text = 'AUs'::text THEN v2_gpu_mos_enaf_plu_plui_2021.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_aus
           FROM visufoncier.v2_gpu_mos_enaf_plu_plui_2021
          GROUP BY v2_gpu_mos_enaf_plu_plui_2021.insee_com
        ), secteurcc AS (
         SELECT v2_gpu_mos_enaf_cc_2021.insee_com,
            COALESCE(sum(
                CASE
                    WHEN v2_gpu_mos_enaf_cc_2021.typesect::text = '01'::text THEN st_area(v2_gpu_mos_enaf_cc_2021.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_01,
            COALESCE(sum(
                CASE
                    WHEN v2_gpu_mos_enaf_cc_2021.typesect::text = '02'::text THEN st_area(v2_gpu_mos_enaf_cc_2021.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_02,
            COALESCE(sum(st_area(v2_gpu_mos_enaf_cc_2021.geom) / 10000.0::double precision), 0::double precision) AS surface_secteurcc_total
           FROM visufoncier.v2_gpu_mos_enaf_cc_2021
          GROUP BY v2_gpu_mos_enaf_cc_2021.insee_com
        ), calc_ajust AS (
         SELECT v2_gpu_mos_enaf_plu_plui_2021_ajust.insee_com,
            COALESCE(st_area(st_union(v2_gpu_mos_enaf_plu_plui_2021_ajust.geom)) / 10000.0::double precision, 0::double precision) AS surface_total_ajust,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui_2021_ajust.typezone::text = 'U'::text THEN v2_gpu_mos_enaf_plu_plui_2021_ajust.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_u_ajust,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui_2021_ajust.typezone::text = 'AUc'::text THEN v2_gpu_mos_enaf_plu_plui_2021_ajust.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_auc_ajust,
            COALESCE(st_area(st_union(
                CASE
                    WHEN v2_gpu_mos_enaf_plu_plui_2021_ajust.typezone::text = 'AUs'::text THEN v2_gpu_mos_enaf_plu_plui_2021_ajust.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_aus_ajust
           FROM visufoncier.v2_gpu_mos_enaf_plu_plui_2021_ajust
          GROUP BY v2_gpu_mos_enaf_plu_plui_2021_ajust.insee_com
        ), secteurcc_ajust AS (
         SELECT v2_gpu_mos_enaf_cc_2021_ajust.insee_com,
            COALESCE(sum(
                CASE
                    WHEN v2_gpu_mos_enaf_cc_2021_ajust.typesect::text = '01'::text THEN st_area(v2_gpu_mos_enaf_cc_2021_ajust.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_01_ajust,
            COALESCE(sum(
                CASE
                    WHEN v2_gpu_mos_enaf_cc_2021_ajust.typesect::text = '02'::text THEN st_area(v2_gpu_mos_enaf_cc_2021_ajust.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_02_ajust,
            COALESCE(sum(st_area(v2_gpu_mos_enaf_cc_2021_ajust.geom) / 10000.0::double precision), 0::double precision) AS surface_secteurcc_total_ajust
           FROM visufoncier.v2_gpu_mos_enaf_cc_2021_ajust
          GROUP BY v2_gpu_mos_enaf_cc_2021_ajust.insee_com
        )
 SELECT a.insee_com,
    a.nom_commune,
    a.nom_epci,
    a.nom_scot,
    a.insee_dep,
    a.nom_departement,
    COALESCE(calc.surface_total, 0::double precision) AS surface_total,
    COALESCE(calc.surface_u, 0::double precision) AS surface_u,
    COALESCE(calc.surface_auc, 0::double precision) AS surface_auc,
    COALESCE(calc.surface_aus, 0::double precision) AS surface_aus,
    COALESCE(secteurcc.surface_secteurcc_01, 0::double precision) AS surface_secteurcc_01,
    COALESCE(secteurcc.surface_secteurcc_02, 0::double precision) AS surface_secteurcc_02,
    COALESCE(secteurcc.surface_secteurcc_total, 0::double precision) AS surface_secteurcc_total,
    COALESCE(calc_ajust.surface_total_ajust, 0::double precision) AS surface_total_ajust,
    COALESCE(calc_ajust.surface_u_ajust, 0::double precision) AS surface_u_ajust,
    COALESCE(calc_ajust.surface_auc_ajust, 0::double precision) AS surface_auc_ajust,
    COALESCE(calc_ajust.surface_aus_ajust, 0::double precision) AS surface_aus_ajust,
    COALESCE(secteurcc_ajust.surface_secteurcc_01_ajust, 0::double precision) AS surface_secteurcc_01_ajust,
    COALESCE(secteurcc_ajust.surface_secteurcc_02_ajust, 0::double precision) AS surface_secteurcc_02_ajust,
    COALESCE(secteurcc_ajust.surface_secteurcc_total_ajust, 0::double precision) AS surface_secteurcc_total_ajust
   FROM communes a
     LEFT JOIN calc ON a.insee_com::text = calc.insee_com::text
     LEFT JOIN secteurcc ON a.insee_com::text = secteurcc.insee_com::text
     LEFT JOIN calc_ajust ON a.insee_com::text = calc_ajust.insee_com::text
     LEFT JOIN secteurcc_ajust ON a.insee_com::text = secteurcc_ajust.insee_com::text
WITH DATA;

CREATE INDEX idx_v2_gpu_epci_2021 ON visufoncier.v2_mos_foncier_agrege_gpu_2021_view USING btree (nom_epci);
CREATE INDEX idx_v2_gpu_insee_2021 ON visufoncier.v2_mos_foncier_agrege_gpu_2021_view USING btree (insee_com);
CREATE INDEX idx_v2_gpu_scot_2021 ON visufoncier.v2_mos_foncier_agrege_gpu_2021_view USING btree (nom_scot);

GRANT SELECT ON visufoncier.v2_mos_foncier_agrege_gpu_2021_view TO "app-visufoncier";
GRANT ALL ON visufoncier.v2_mos_foncier_agrege_gpu_2021_view TO "margot.leborgne";
GRANT SELECT ON visufoncier.v2_mos_foncier_agrege_gpu_2021_view TO "www-data";