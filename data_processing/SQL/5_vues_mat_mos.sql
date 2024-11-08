
------------------------------------------------------------------------------------------------------------------------------
--Création des vues matérialisées -- données reliées au tableau de bord superset 
-------------------------------------------------------------------------------------------------------------------------------

-- visufoncier.mos_foncier_agrege_com_liengeo_view source
--Vue matérialsée qui gère tous les filtres du tableau de bord partie MOS

--Si modification dans les données
-- Rafraîchir les vues matérialisées si il y a des modifications dans les tables associées :
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_conso_view;
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_insee_temporel_view;
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_liengeo_view;
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_temporel_view;
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_enaf_nature2021_det_view;
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_gpu_view;
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2011_nature_2021_view;
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2011_view;
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2021_det_densification_view;
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2021_det_tot_view;
REFRESH MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2021_det_view;

--Pour recreer les vues (si on veut les modifier), repartir de ces syntaxes en les adaptant : 

--Supprime la vue si elle existe
DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_com_liengeo_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_liengeo_view
TABLESPACE pg_default
AS WITH aggregated_geom AS (
         SELECT mos_foncier_agrege_com.insee_com,
            mos_foncier_agrege_com.nom_commune,
            mos_foncier_agrege_com.nom_epci,
            mos_foncier_agrege_com.nom_scot,
            'Communes'::text AS type_territoire,
            mos_foncier_agrege_com.nom_commune AS territoire,
            mos_foncier_agrege_com.nom_departement,
            st_centroid(mos_foncier_agrege_com.geom) AS centroid_geom,
            14 AS z,
            mos_foncier_agrege_com.millesime_debut,
            mos_foncier_agrege_com.millesime_fin,
            date_part('year'::text, mos_foncier_agrege_com.millesime_debut) AS annee_debut,
            date_part('year'::text, mos_foncier_agrege_com.millesime_fin) AS annee_fin
           FROM visufoncier.mos_foncier_agrege_com
        UNION ALL
         SELECT NULL::character varying AS insee_com,
            NULL::character varying AS nom_commune,
            NULL::character varying AS nom_epci,
            NULL::character varying AS nom_scot,
            'Département'::text AS type_territoire,
            mos_foncier_agrege_com.nom_departement AS territoire,
            mos_foncier_agrege_com.nom_departement,
            st_centroid(st_collect(mos_foncier_agrege_com.geom)) AS centroid_geom,
            12 AS z,
            min(mos_foncier_agrege_com.millesime_debut) AS millesime_debut,
            max(mos_foncier_agrege_com.millesime_fin) AS millesime_fin,
            date_part('year'::text, min(mos_foncier_agrege_com.millesime_debut)) AS annee_debut,
            date_part('year'::text, max(mos_foncier_agrege_com.millesime_fin)) AS annee_fin
           FROM visufoncier.mos_foncier_agrege_com
          WHERE "left"(mos_foncier_agrege_com.insee_com::text, 2) = ANY (ARRAY['35'::text, '22'::text, '56'::text, '29'::text])
          GROUP BY mos_foncier_agrege_com.nom_departement
        UNION ALL
         SELECT NULL::character varying AS insee_com,
            NULL::character varying AS nom_commune,
            mos_foncier_agrege_com.nom_epci,
            mos_foncier_agrege_com.nom_scot,
            'EPCI'::text AS type_territoire,
            mos_foncier_agrege_com.nom_epci AS territoire,
            mos_foncier_agrege_com.nom_departement,
            st_centroid(st_collect(mos_foncier_agrege_com.geom)) AS centroid_geom,
            11 AS z,
            min(mos_foncier_agrege_com.millesime_debut) AS millesime_debut,
            max(mos_foncier_agrege_com.millesime_fin) AS millesime_fin,
            date_part('year'::text, min(mos_foncier_agrege_com.millesime_debut)) AS annee_debut,
            date_part('year'::text, max(mos_foncier_agrege_com.millesime_fin)) AS annee_fin
           FROM visufoncier.mos_foncier_agrege_com
          GROUP BY mos_foncier_agrege_com.nom_epci, mos_foncier_agrege_com.nom_scot, mos_foncier_agrege_com.nom_departement
        UNION ALL
         SELECT NULL::character varying AS insee_com,
            NULL::character varying AS nom_commune,
            NULL::character varying AS nom_epci,
            mos_foncier_agrege_com.nom_scot,
            'SCOT'::text AS type_territoire,
            mos_foncier_agrege_com.nom_scot AS territoire,
            mos_foncier_agrege_com.nom_departement,
            st_centroid(st_collect(mos_foncier_agrege_com.geom)) AS centroid_geom,
            11 AS z,
            min(mos_foncier_agrege_com.millesime_debut) AS millesime_debut,
            max(mos_foncier_agrege_com.millesime_fin) AS millesime_fin,
            date_part('year'::text, min(mos_foncier_agrege_com.millesime_debut)) AS annee_debut,
            date_part('year'::text, max(mos_foncier_agrege_com.millesime_fin)) AS annee_fin
           FROM visufoncier.mos_foncier_agrege_com
          GROUP BY mos_foncier_agrege_com.nom_scot, mos_foncier_agrege_com.nom_departement
        UNION ALL
         SELECT NULL::character varying AS insee_com,
            NULL::character varying AS nom_commune,
            NULL::character varying AS nom_epci,
            NULL::character varying AS nom_scot,
            'Région'::text AS type_territoire,
            'Bretagne'::character varying AS territoire,
            NULL::character varying AS nom_departement,
            NULL::geometry AS centroid_geom,
            8 AS z,
            min(mos_foncier_agrege_com.millesime_debut) AS millesime_debut,
            max(mos_foncier_agrege_com.millesime_fin) AS millesime_fin,
            date_part('year'::text, min(mos_foncier_agrege_com.millesime_debut)) AS annee_debut,
            date_part('year'::text, max(mos_foncier_agrege_com.millesime_fin)) AS annee_fin
           FROM visufoncier.mos_foncier_agrege_com
        )
 SELECT aggregated_geom.insee_com,
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
    round(st_x(st_transform(aggregated_geom.centroid_geom, 3857))::numeric, 4) AS x,
    round(st_y(st_transform(aggregated_geom.centroid_geom, 3857))::numeric, 4) AS y,
    aggregated_geom.z::numeric AS z
   FROM aggregated_geom
WITH DATA;


COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_liengeo_view IS
  'Vue matérialisée pour la partie filtres géographiques et filtres temporels et la cartographie, x,y,z. Reliée au tableau de bord superset';


-- visufoncier.mos_foncier_agrege_com_conso_view source
DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_com_conso_view;

-- Créer la vue matérialisée avec les données agrégées
-- visufoncier.mos_foncier_agrege_com_conso_view source
--Vue matérialisée du MOS 2011 2021 avec les indicateurs agrégés par commune et filtré sur les flux de consommation

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_conso_view
TABLESPACE pg_default
AS SELECT st_multi(st_union(a.geom)) AS geom,
    a.insee_com,
    a.nom_commune,
    a.nom_epci,
    a.insee_dep,
    a.nom_scot,
    a.nom_departement,
    a.millesime_debut,
    a.millesime_fin,
    round(sum(a.surface_calc_m2)::numeric, 2) AS total_surface_calc_m2,
    round(sum(a.surface_calc_ha)::numeric, 2) AS total_surface_calc_ha,
    sd.surf_conso_2011,
    w.surface_calc_ha_sansinfra,
    replace(w.exclusion_infrastrctures::text, ','::text, '.'::text)::numeric AS exclusion_infrastrctures,
    ip.pmun2020::numeric AS pnum20,
    ip.pmun2011::numeric AS pnum11,
    ip.pmun2020::numeric - ip.pmun2011::numeric AS diff_pop1120
   FROM visufoncier.mos_foncier_agrege a
     LEFT JOIN visufoncier.mos_foncier_agrege_com sd ON a.insee_com::text = sd.insee_com::text
     LEFT JOIN visufoncier.mos_foncier_corr_adeupa w ON a.insee_com::text = w.code_insee::text
     LEFT JOIN visufoncier.insee_popmun ip ON a.insee_com::text = ip.codgeo::text
  WHERE a.flux_conso = 1
  GROUP BY a.insee_com, a.nom_commune, a.nom_epci, a.insee_dep, a.nom_scot, a.nom_departement, a.millesime_debut, a.millesime_fin, sd.surf_conso_2011, w.surface_calc_ha_sansinfra, w.exclusion_infrastrctures, ip.pmun2020, ip.pmun2011
WITH DATA;

-- View indexes:
CREATE INDEX idx_geom_mos_foncier_agrege_com_conso_view ON visufoncier.mos_foncier_agrege_com_conso_view USING gist (geom);


-- Ajouter un commentaire à la vue matérialisée
COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_conso_view IS
  'Vue matérialisée du MOS 2011 2021 avec les indicateurs agrégés par commune et filtré sur les flux de consommation, enaf vers conso entre 2011 et 2021. Reliée au tableau de bord superset';

-- visufoncier.mos_foncier_agrege_com_temporel_view source
--Vue matérialisée temporelle pour l''onglet indicateur reliée à la table agrégée par commune

DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_com_temporel_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_temporel_view
TABLESPACE pg_default
AS SELECT mos_foncier_agrege_com.insee_com,
    mos_foncier_agrege_com.nom_commune,
    mos_foncier_agrege_com.nom_epci,
    mos_foncier_agrege_com.nom_scot,
    mos_foncier_agrege_com.nom_departement,
    mos_foncier_agrege_com.millesime_debut,
    mos_foncier_agrege_com.millesime_fin,
    '2020-01-01 00:00:00'::timestamp without time zone AS annee,
    mos_foncier_agrege_com.pnum20 AS population,
    mos_foncier_agrege_com.p20_emplt AS emplt,
    mos_foncier_agrege_com.c20_men AS menage,
    mos_foncier_agrege_com.surf_conso_2021 AS surf_conso
   FROM visufoncier.mos_foncier_agrege_com
UNION ALL
 SELECT mos_foncier_agrege_com.insee_com,
    mos_foncier_agrege_com.nom_commune,
    mos_foncier_agrege_com.nom_epci,
    mos_foncier_agrege_com.nom_scot,
    mos_foncier_agrege_com.nom_departement,
    mos_foncier_agrege_com.millesime_debut,
    mos_foncier_agrege_com.millesime_fin,
    '2011-01-01 00:00:00'::timestamp without time zone AS annee,
    mos_foncier_agrege_com.pnum11 AS population,
    mos_foncier_agrege_com.p11_emplt AS emplt,
    mos_foncier_agrege_com.c11_men AS menage,
    mos_foncier_agrege_com.surf_conso_2011 AS surf_conso
   FROM visufoncier.mos_foncier_agrege_com
  ORDER BY 1
WITH DATA;

-- Ajouter un commentaire à la vue matérialisée
COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_temporel_view IS 'Pour les évolutions temporelles dans l''onglet indicateurs du tableau de bord superset Visufoncier.';


--Vue matérialisée temporelle pour l''onglet indicateur reliée aux données INSEE
--Ajouter les nouvelles années traitées dans cette vue que ce soit pour le MOS ou l'OCS GE

DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_com_insee_temporel_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_insee_temporel_view
TABLESPACE pg_default
AS 
-- Données pour l'année 2020
SELECT 
    mos_foncier_agrege_com.insee_com,
    mos_foncier_agrege_com.nom_commune,
    mos_foncier_agrege_com.nom_epci,
    mos_foncier_agrege_com.nom_scot,
    mos_foncier_agrege_com.nom_departement,
    mos_foncier_agrege_com.millesime_debut,
    mos_foncier_agrege_com.millesime_fin,
    '2020-01-01 00:00:00'::timestamp without time zone AS annee,
    insee_popmun.pmun2020 AS population, 
    insee_emploi_2020.p20_emplt AS emplt,
    insee_menage_2020.c20_men AS menage 
FROM 
    visufoncier.mos_foncier_agrege_com
JOIN 
    visufoncier.insee_popmun ON mos_foncier_agrege_com.insee_com = insee_popmun.codgeo
JOIN 
    visufoncier.insee_emploi_2020 ON mos_foncier_agrege_com.insee_com = insee_emploi_2020.codgeo
JOIN 
    visufoncier.insee_menage_2020 ON mos_foncier_agrege_com.insee_com = insee_menage_2020.codgeo

UNION ALL

-- Données pour l'année 2018
SELECT 
    mos_foncier_agrege_com.insee_com,
    mos_foncier_agrege_com.nom_commune,
    mos_foncier_agrege_com.nom_epci,
    mos_foncier_agrege_com.nom_scot,
    mos_foncier_agrege_com.nom_departement,
    mos_foncier_agrege_com.millesime_debut,
    mos_foncier_agrege_com.millesime_fin,
    '2018-01-01 00:00:00'::timestamp without time zone AS annee,
    insee_popmun.pmun2018 AS population, 
    insee_emploi_2018.p18_emplt AS emplt,
    insee_menage_2018.c18_men AS menage 
FROM 
    visufoncier.mos_foncier_agrege_com
JOIN 
    visufoncier.insee_popmun ON mos_foncier_agrege_com.insee_com = insee_popmun.codgeo
JOIN 
    visufoncier.insee_emploi_2018 ON mos_foncier_agrege_com.insee_com = insee_emploi_2018.codgeo
JOIN 
    visufoncier.insee_menage_2018 ON mos_foncier_agrege_com.insee_com = insee_menage_2018.codgeo

UNION ALL

-- Données pour l'année 2017
SELECT 
    mos_foncier_agrege_com.insee_com,
    mos_foncier_agrege_com.nom_commune,
    mos_foncier_agrege_com.nom_epci,
    mos_foncier_agrege_com.nom_scot,
    mos_foncier_agrege_com.nom_departement,
    mos_foncier_agrege_com.millesime_debut,
    mos_foncier_agrege_com.millesime_fin,
    '2017-01-01 00:00:00'::timestamp without time zone AS annee,
    insee_popmun.pmun2017 AS population, 
    insee_emploi_2017.p17_emplt AS emplt,
    insee_menage_2017.c17_men AS menage 
FROM 
    visufoncier.mos_foncier_agrege_com
JOIN 
    visufoncier.insee_popmun ON mos_foncier_agrege_com.insee_com = insee_popmun.codgeo
JOIN 
    visufoncier.insee_emploi_2017 ON mos_foncier_agrege_com.insee_com = insee_emploi_2017.codgeo
JOIN 
    visufoncier.insee_menage_2017 ON mos_foncier_agrege_com.insee_com = insee_menage_2017.codgeo

UNION ALL

-- Données pour l'année 2011
SELECT 
    mos_foncier_agrege_com.insee_com,
    mos_foncier_agrege_com.nom_commune,
    mos_foncier_agrege_com.nom_epci,
    mos_foncier_agrege_com.nom_scot,
    mos_foncier_agrege_com.nom_departement,
    mos_foncier_agrege_com.millesime_debut,
    mos_foncier_agrege_com.millesime_fin,
    '2011-01-01 00:00:00'::timestamp without time zone AS annee,
    insee_popmun.pmun2011 AS population, 
    insee_emploi_2011.p11_emplt AS emplt,
    insee_menage_2011.c11_men AS menage 
FROM 
    visufoncier.mos_foncier_agrege_com
JOIN 
    visufoncier.insee_popmun ON mos_foncier_agrege_com.insee_com = insee_popmun.codgeo
JOIN 
    visufoncier.insee_emploi_2011 ON mos_foncier_agrege_com.insee_com = insee_emploi_2011.codgeo
JOIN 
    visufoncier.insee_menage_2011 ON mos_foncier_agrege_com.insee_com = insee_menage_2011.codgeo

ORDER BY 
    insee_com
WITH DATA;


-- Ajouter un commentaire à la vue matérialisée
COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_com_insee_temporel_view IS 'Vue matérialisée qui regroupe les informations des fichiers INSEE téléchargés via les syntaxes Python. Reliée au tableau de bord Superset.';


--Partie vue mat pour l'onglet consommation 
-- visufoncier.mos_foncier_agrege_enaf_nature2021_det_view source
DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_enaf_nature2021_det_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_enaf_nature2021_det_view
TABLESPACE pg_default
AS SELECT mos_foncier_agrege.nature_2021,
    mos_foncier_agrege.nature_det_2021,
    mos_foncier_agrege.insee_com,
    mos_foncier_agrege.nom_commune,
    mos_foncier_agrege.nom_epci,
    mos_foncier_agrege.nom_scot,
    mos_foncier_agrege.nom_departement,
    mos_foncier_agrege.millesime_debut,
    mos_foncier_agrege.millesime_fin,
    sum(mos_foncier_agrege.surface_calc_ha) AS total_surface_ha
   FROM visufoncier.mos_foncier_agrege
  WHERE mos_foncier_agrege.enaf_conso_2021::text <> 'conso'::text
  GROUP BY mos_foncier_agrege.nature_2021, mos_foncier_agrege.nature_det_2021, mos_foncier_agrege.insee_com, mos_foncier_agrege.nom_commune, mos_foncier_agrege.nom_epci,mos_foncier_agrege.nom_departement, mos_foncier_agrege.nom_scot,mos_foncier_agrege.millesime_debut,mos_foncier_agrege.millesime_fin
  ORDER BY (sum(mos_foncier_agrege.surface_calc_ha)) DESC
WITH DATA;

-- View indexes:
CREATE INDEX idx_nom_epci_commune_scot_enaf_nature2021_det_view ON visufoncier.mos_foncier_agrege_enaf_nature2021_det_view USING btree (nom_epci, nom_commune, nom_scot, nom_departement);

COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_enaf_nature2021_det_view IS 'Vue matérialisée qui regroupe les données de la table mos_foncier_agrege pour l''année 2021, en excluant les données de consommation ("conso"). Elle agrège la surface totale par nature et nature détaillée pour chaque commune, EPCI, département, et SCOT. Utilisée pour l''analyse des consommations foncières par nature du sol en 2021.';


-- visufoncier.mos_foncier_agrege_nature2011_nature_2021_view source
DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_nature2011_nature_2021_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2011_nature_2021_view
TABLESPACE pg_default
AS SELECT mos_foncier_agrege.nature_2011,
    mos_foncier_agrege.nature_2021,
    mos_foncier_agrege.insee_com,
    mos_foncier_agrege.nom_commune,
    mos_foncier_agrege.nom_epci,
    mos_foncier_agrege.nom_scot,
    mos_foncier_agrege.nom_departement,
    mos_foncier_agrege.millesime_debut,
    mos_foncier_agrege.millesime_fin,
    sum(mos_foncier_agrege.surface_calc_ha) AS total_surface_ha
   FROM visufoncier.mos_foncier_agrege
  WHERE mos_foncier_agrege.flux_conso = 1
  GROUP BY mos_foncier_agrege.nature_2011, mos_foncier_agrege.nature_2021, mos_foncier_agrege.insee_com, mos_foncier_agrege.nom_commune, mos_foncier_agrege.nom_epci, mos_foncier_agrege.nom_departement,mos_foncier_agrege.nom_scot,mos_foncier_agrege.millesime_debut,mos_foncier_agrege.millesime_fin
  ORDER BY (sum(mos_foncier_agrege.surface_calc_ha)) DESC
WITH DATA;

-- View indexes:
CREATE INDEX idx_nom_epci_commune_scot_nature2011_nature_2021_view ON visufoncier.mos_foncier_agrege_nature2011_nature_2021_view USING btree (nom_epci, nom_commune, nom_scot, nom_departement);

COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2011_nature_2021_view IS 'Vue matérialisée qui regroupe les données de la table mos_foncier_agrege pour l''analyse des flux de consommation foncière entre les années 2011 et 2021. Elle agrège la surface totale par nature de sol pour chaque commune, EPCI, département, et SCOT, en filtrant sur les flux de consommation. Utilisée pour l''analyse des changements de nature du sol entre 2011 et 2021.';


-- visufoncier.mos_foncier_agrege_nature2011_view source
DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_nature2011_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2011_view
TABLESPACE pg_default
AS SELECT mos_foncier_agrege.nature_2011,
    mos_foncier_agrege.nature_2021,
    mos_foncier_agrege.insee_com,
    mos_foncier_agrege.nom_commune,
    mos_foncier_agrege.nom_epci,
    mos_foncier_agrege.nom_scot,
    mos_foncier_agrege.nom_departement,
    mos_foncier_agrege.millesime_debut,
    mos_foncier_agrege.millesime_fin,
    sum(mos_foncier_agrege.surface_calc_ha) AS total_surface_ha
   FROM visufoncier.mos_foncier_agrege
  WHERE mos_foncier_agrege.flux_conso = 1
  GROUP BY mos_foncier_agrege.nature_2011, mos_foncier_agrege.nature_2021, mos_foncier_agrege.insee_com, mos_foncier_agrege.nom_commune, mos_foncier_agrege.nom_epci, mos_foncier_agrege.nom_departement,mos_foncier_agrege.nom_scot, mos_foncier_agrege.millesime_debut,mos_foncier_agrege.millesime_fin
  ORDER BY (sum(mos_foncier_agrege.surface_calc_ha)) DESC
WITH DATA;

-- View indexes:
CREATE INDEX idx_nom_epci_commune_scot_nature2011_view ON visufoncier.mos_foncier_agrege_nature2011_view USING btree (nom_epci, nom_commune, nom_scot,nom_departement);

COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2011_view IS 'Vue matérialisée qui regroupe les données de la table mos_foncier_agrege pour l''analyse des flux de consommation foncière entre les années 2011 et 2021. Elle agrège la surface totale par nature de sol pour chaque commune, EPCI, département, et SCOT, en filtrant sur les flux de consommation. Utilisée pour l''analyse des changements de nature du sol entre 2011 et 2021, en se concentrant uniquement sur les zones de consommation.';


-- visufoncier.mos_foncier_agrege_nature2021_det_densification_view source
DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_nature2021_det_densification_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2021_det_densification_view
TABLESPACE pg_default
AS SELECT mos_foncier_agrege.code4_2021,
    mos_foncier_agrege.nature_det_2021,
    mos_foncier_agrege.insee_com,
    mos_foncier_agrege.nom_commune,
    mos_foncier_agrege.nom_epci,
    mos_foncier_agrege.nom_scot,
    mos_foncier_agrege.nom_departement,
    mos_foncier_agrege.millesime_debut,
    mos_foncier_agrege.millesime_fin,
    sum(mos_foncier_agrege.surface_calc_ha) AS total_surface_ha
   FROM visufoncier.mos_foncier_agrege
  WHERE mos_foncier_agrege.code4_2021::text = ANY (ARRAY['1331'::character varying, '1332'::character varying, '1227'::character varying, '1228'::character varying, '1335'::character varying, '1413'::character varying, '1414'::character varying]::text[])
  GROUP BY mos_foncier_agrege.code4_2021, mos_foncier_agrege.nature_det_2021, mos_foncier_agrege.insee_com, mos_foncier_agrege.nom_commune, mos_foncier_agrege.nom_epci,  mos_foncier_agrege.nom_departement, mos_foncier_agrege.nom_scot, mos_foncier_agrege.millesime_debut, mos_foncier_agrege.millesime_fin
  ORDER BY (sum(mos_foncier_agrege.surface_calc_ha)) DESC
WITH DATA;

-- View indexes:
CREATE INDEX idx_nom_epci_commune_scot_nature2021_det_densification_view ON visufoncier.mos_foncier_agrege_nature2021_det_densification_view USING btree (nom_epci, nom_commune, nom_scot,nom_departement);

COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2021_det_densification_view IS 'Vue matérialisée qui regroupe les données de la table mos_foncier_agrege pour l''analyse de la densification en 2021. Elle agrège la surface totale par code 4 et nature de sol pour chaque commune, EPCI, département, et SCOT, en se concentrant sur des zones spécifiques définies par leurs codes 4 (relatives à la densification) et filtrées sur des valeurs particulières. Utilisée pour l''analyse de la densification du foncier en 2021.';


-- visufoncier.mos_foncier_agrege_nature2021_det_tot_view source
DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_nature2021_det_tot_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2021_det_tot_view
TABLESPACE pg_default
AS SELECT mos_foncier_agrege.nature_2021,
    mos_foncier_agrege.nature_det_2021,
    mos_foncier_agrege.insee_com,
    mos_foncier_agrege.nom_commune,
    mos_foncier_agrege.nom_epci,
    mos_foncier_agrege.nom_scot,
    mos_foncier_agrege.nom_departement,
    mos_foncier_agrege.millesime_debut,
    mos_foncier_agrege.millesime_fin,
    sum(mos_foncier_agrege.surface_calc_ha) AS total_surface_ha
   FROM visufoncier.mos_foncier_agrege
  GROUP BY mos_foncier_agrege.nature_2021, mos_foncier_agrege.nature_det_2021, mos_foncier_agrege.insee_com, mos_foncier_agrege.nom_commune, mos_foncier_agrege.nom_epci, mos_foncier_agrege.nom_departement,mos_foncier_agrege.nom_scot,mos_foncier_agrege.millesime_debut,mos_foncier_agrege.millesime_fin
  ORDER BY (sum(mos_foncier_agrege.surface_calc_ha)) DESC
WITH DATA;

-- View indexes:
CREATE INDEX idx_nom_epci_commune_scot_nature_2021_det_tot_view ON visufoncier.mos_foncier_agrege_nature2021_det_tot_view USING btree (nom_epci, nom_commune, nom_scot,nom_departement);

COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2021_det_tot_view IS 'Vue matérialisée qui agrège les données de la table mos_foncier_agrege pour l''année 2021, en totalisant la surface des différents types de sols et leur nature. La vue regroupe les informations par nature de sol, nature de détail, et les différents niveaux administratifs (commune, EPCI, SCOT, département) tout en tenant compte des millésimes associés. Elle fournit un total de la surface par catégorie pour l''analyse foncière dans la région.';


-- visufoncier.mos_foncier_agrege_nature2021_det_view source
DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_nature2021_det_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2021_det_view
TABLESPACE pg_default
AS SELECT mos_foncier_agrege.nature_2021,
    mos_foncier_agrege.nature_det_2021,
    mos_foncier_agrege.insee_com,
    mos_foncier_agrege.nom_commune,
    mos_foncier_agrege.nom_epci,
    mos_foncier_agrege.nom_scot,
    mos_foncier_agrege.nom_departement,
    mos_foncier_agrege.millesime_debut,
    mos_foncier_agrege.millesime_fin,
    sum(mos_foncier_agrege.surface_calc_ha) AS total_surface_ha
   FROM visufoncier.mos_foncier_agrege
  WHERE mos_foncier_agrege.flux_conso = 1
  GROUP BY mos_foncier_agrege.nature_2021, mos_foncier_agrege.nature_det_2021, mos_foncier_agrege.insee_com, mos_foncier_agrege.nom_commune, mos_foncier_agrege.nom_epci, mos_foncier_agrege.nom_departement,mos_foncier_agrege.nom_scot,mos_foncier_agrege.millesime_debut,mos_foncier_agrege.millesime_fin
  ORDER BY (sum(mos_foncier_agrege.surface_calc_ha)) DESC
WITH DATA;

-- View indexes:
CREATE INDEX idx_nom_epci_commune_scot_nature_2021_det_view ON visufoncier.mos_foncier_agrege_nature2021_det_view USING btree (nom_epci, nom_commune, nom_scot,nom_departement);

COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_nature2021_det_view IS 'Vue matérialisée qui agrège les données de la table mos_foncier_agrege pour l''année 2021, en totalisant la surface des différentes natures de sol et leurs détails. La vue se concentre sur les flux de consommation des sols, représentés par le filtre flux_conso = 1. Elle regroupe les informations par nature de sol, nature de détail, et les niveaux administratifs (commune, EPCI, SCOT, département), tout en tenant compte des millésimes associés, permettant ainsi une analyse détaillée de la consommation foncière.';


-- visufoncier.mos_foncier_agrege_gpu_view 
DROP MATERIALIZED VIEW IF EXISTS visufoncier.mos_foncier_agrege_gpu_view;

CREATE MATERIALIZED VIEW visufoncier.mos_foncier_agrege_gpu_view
TABLESPACE pg_default
AS WITH calc AS (
         SELECT gpu_mos_enaf_plu_plui.insee_com,
            COALESCE(st_area(st_union(gpu_mos_enaf_plu_plui.geom)) / 10000.0::double precision, 0::double precision) AS surface_total,
            COALESCE(st_area(st_union(
                CASE
                    WHEN gpu_mos_enaf_plu_plui.typezone::text = 'U'::text THEN gpu_mos_enaf_plu_plui.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_u,
            COALESCE(st_area(st_union(
                CASE
                    WHEN gpu_mos_enaf_plu_plui.typezone::text = 'AUc'::text THEN gpu_mos_enaf_plu_plui.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_auc,
            COALESCE(st_area(st_union(
                CASE
                    WHEN gpu_mos_enaf_plu_plui.typezone::text = 'AUs'::text THEN gpu_mos_enaf_plu_plui.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_aus
           FROM visufoncier.gpu_mos_enaf_plu_plui
          GROUP BY gpu_mos_enaf_plu_plui.insee_com
        ), secteurcc AS (
         SELECT gpu_mos_enaf_cc.insee_com,
            COALESCE(sum(
                CASE
                    WHEN gpu_mos_enaf_cc.typesect::text = '01'::text THEN st_area(gpu_mos_enaf_cc.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_01,
            COALESCE(sum(
                CASE
                    WHEN gpu_mos_enaf_cc.typesect::text = '02'::text THEN st_area(gpu_mos_enaf_cc.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_02,
            COALESCE(sum(st_area(gpu_mos_enaf_cc.geom) / 10000.0::double precision), 0::double precision) AS surface_secteurcc_total
           FROM visufoncier.gpu_mos_enaf_cc
          GROUP BY gpu_mos_enaf_cc.insee_com
        ), calc_ajust AS (
         SELECT gpu_mos_enaf_plu_plui_ajust.insee_com,
            COALESCE(st_area(st_union(gpu_mos_enaf_plu_plui_ajust.geom)) / 10000.0::double precision, 0::double precision) AS surface_total_ajust,
            COALESCE(st_area(st_union(
                CASE
                    WHEN gpu_mos_enaf_plu_plui_ajust.typezone::text = 'U'::text THEN gpu_mos_enaf_plu_plui_ajust.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_u_ajust,
            COALESCE(st_area(st_union(
                CASE
                    WHEN gpu_mos_enaf_plu_plui_ajust.typezone::text = 'AUc'::text THEN gpu_mos_enaf_plu_plui_ajust.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_auc_ajust,
            COALESCE(st_area(st_union(
                CASE
                    WHEN gpu_mos_enaf_plu_plui_ajust.typezone::text = 'AUs'::text THEN gpu_mos_enaf_plu_plui_ajust.geom
                    ELSE NULL::geometry
                END)) / 10000.0::double precision, 0::double precision) AS surface_aus_ajust
           FROM visufoncier.gpu_mos_enaf_plu_plui_ajust
          GROUP BY gpu_mos_enaf_plu_plui_ajust.insee_com
           ), secteurcc_ajust AS (
         SELECT gpu_mos_enaf_cc_ajust.insee_com,
            COALESCE(sum(
                CASE
                    WHEN gpu_mos_enaf_cc_ajust.typesect::text = '01'::text THEN st_area(gpu_mos_enaf_cc_ajust.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_01_ajust,
            COALESCE(sum(
                CASE
                    WHEN gpu_mos_enaf_cc_ajust.typesect::text = '02'::text THEN st_area(gpu_mos_enaf_cc_ajust.geom) / 10000.0::double precision
                    ELSE 0::double precision
                END), 0::double precision) AS surface_secteurcc_02_ajust,
            COALESCE(sum(st_area(gpu_mos_enaf_cc_ajust.geom) / 10000.0::double precision), 0::double precision) AS surface_secteurcc_total_ajust
           FROM visufoncier.gpu_mos_enaf_cc_ajust
          GROUP BY gpu_mos_enaf_cc_ajust.insee_com
        )
 SELECT a.insee_com,
    a.nom_commune,
    a.nom_epci,
    a.insee_dep,
    a.nom_scot,
    a.nom_departement,
    a.millesime_debut,
    a.millesime_fin,
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
 FROM visufoncier.mos_foncier_agrege_com a
     LEFT JOIN calc ON a.insee_com::text = calc.insee_com::text
     LEFT JOIN secteurcc ON a.insee_com::text = secteurcc.insee_com::text
     LEFT JOIN calc_ajust ON a.insee_com::text = calc_ajust.insee_com::text
     LEFT JOIN secteurcc_ajust ON a.insee_com::text = secteurcc_ajust.insee_com::text
WITH DATA;

-- Ajouter un commentaire à la vue matérialisée
COMMENT ON MATERIALIZED VIEW visufoncier.mos_foncier_agrege_gpu_view IS
  'Table du MOS enaf croisée avec les données du GPU (PLU,PLUi et cartes communales). Reliée au tableau de bord superset';

