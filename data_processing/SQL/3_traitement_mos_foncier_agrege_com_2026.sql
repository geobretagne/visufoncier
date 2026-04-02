-----------------------------------------------------------
-- TRAITEMENT MOS 2026 - AGRÉGATION PAR COMMUNE
-----------------------------------------------------------
-- Principe :
-- - Les infos géo (EPCI, SCOT, etc.) sont DÉJÀ dans v2_mos_agrege
-- - On agrège juste les surfaces par commune/millésime
-- - Pas de geom ici (sera ajouté dans les vues si nécessaire)
-----------------------------------------------------------

-----------------------------------------------------------
-- ÉTAPE 1 : CRÉATION TABLE AGRÉGÉE PAR COMMUNE (SURFACES UNIQUEMENT)
-----------------------------------------------------------

DROP TABLE IF EXISTS visufoncier.v2_mos_agrege_com CASCADE;

CREATE TABLE visufoncier.v2_mos_agrege_com AS
WITH etat_par_annee AS (
    -- Agrégation des surfaces par commune, millésime et catégorie ENAF/CONSO
    SELECT
        insee_com,
        nom_commune,
        nom_epci,
        nom_scot,
        nom_departement,
        insee_dep,
        insee_reg,
        annee,
        enaf_conso,
        ROUND(SUM(surface_ha)::NUMERIC, 2) as surf_ha,
        COUNT(*) as nb_polygones
    FROM visufoncier.v2_mos_agrege
    GROUP BY insee_com, nom_commune, nom_epci, nom_scot, nom_departement, 
             insee_dep, insee_reg, annee, enaf_conso
)
-- Pivot des surfaces ENAF/CONSO en colonnes
SELECT
    insee_com,
    nom_commune,
    nom_epci,
    nom_scot,
    nom_departement,
    insee_dep,
    insee_reg,
    annee,
    SUM(CASE WHEN enaf_conso = 'enaf' THEN surf_ha ELSE 0 END) as surf_enaf_ha,
    SUM(CASE WHEN enaf_conso = 'conso' THEN surf_ha ELSE 0 END) as surf_conso_ha,
    SUM(surf_ha) as surf_totale_ha,
    SUM(nb_polygones) as nb_polygones
FROM etat_par_annee
GROUP BY insee_com, nom_commune, nom_epci, nom_scot, nom_departement, 
         insee_dep, insee_reg, annee;

-- Indexes
CREATE INDEX idx_v2_agrege_com_insee ON visufoncier.v2_mos_agrege_com (insee_com);
CREATE INDEX idx_v2_agrege_com_annee ON visufoncier.v2_mos_agrege_com (annee);
CREATE INDEX idx_v2_agrege_com_epci ON visufoncier.v2_mos_agrege_com (nom_epci);
CREATE INDEX idx_v2_agrege_com_scot ON visufoncier.v2_mos_agrege_com (nom_scot);
CREATE INDEX idx_v2_agrege_com_dep ON visufoncier.v2_mos_agrege_com (insee_dep);


COMMENT ON TABLE visufoncier.v2_mos_agrege_com IS
'État du MOS par commune et par millésime. Structure temporelle : 1 ligne par commune ET par année (2011, 2021, 2024). Pas de geom.';


-----------------------------------------------------------
-- ÉTAPE 2 : ENRICHISSEMENT DONNÉES INSEE
-----------------------------------------------------------
-- Note : Les données INSEE seront jointes dynamiquement dans les VUES
-- On ne stocke PAS ces données ici pour éviter la redondance et faciliter les mises à jour

-- Option : Si vraiment nécessaire pour performance, créer des colonnes calculées
-- mais privilégier les jointures dans les vues matérialisées


-----------------------------------------------------------
-- ÉTAPE 3 : DROITS
-----------------------------------------------------------

GRANT SELECT ON TABLE visufoncier.v2_mos_agrege_com TO "app-visufoncier";
GRANT ALL ON TABLE visufoncier.v2_mos_agrege_com TO "margot.leborgne";
GRANT SELECT ON TABLE visufoncier.v2_mos_agrege_com TO "www-data";


-----------------------------------------------------------
-- VÉRIFICATIONS
-----------------------------------------------------------

-- Nombre de lignes par commune (doit être 3 : une par millésime)
SELECT insee_com, nom_commune, COUNT(*) as nb_lignes
FROM visufoncier.v2_mos_agrege_com
GROUP BY insee_com, nom_commune
HAVING COUNT(*) != 3
LIMIT 10;

-- Vérification surfaces par millésime
SELECT 
    EXTRACT(YEAR FROM annee) as annee,
    COUNT(DISTINCT insee_com) as nb_communes,
    ROUND(SUM(surf_enaf_ha)::numeric, 2) as total_enaf_ha,
    ROUND(SUM(surf_conso_ha)::numeric, 2) as total_conso_ha,
    ROUND(SUM(surf_totale_ha)::numeric, 2) as total_ha
FROM visufoncier.v2_mos_agrege_com
GROUP BY EXTRACT(YEAR FROM annee)
ORDER BY annee;


-----------------------------------------------------------
-- NOTES POUR PROCHAINS MILLÉSIMES
-----------------------------------------------------------
/*
Pour ajouter le millésime 2027 :

1. Les nouvelles données seront automatiquement dans v2_mos_agrege
   (grâce à la structure pivot du script 2)

2. Rafraîchir cette table :
   DROP TABLE visufoncier.v2_mos_agrege_com CASCADE;
   \i 3_traitement_mos_foncier_agrege_com_2026.sql

3. Rafraîchir les vues matérialisées (voir script 5)

IMPORTANT : Cette table ne contient QUE les surfaces MOS.
Les données INSEE et autres enrichissements se font dans les vues matérialisées (script 5).
*/