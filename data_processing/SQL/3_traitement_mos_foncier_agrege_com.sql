
-----------------------------------------------------------
-- Création de la table mos_foncier_agrege_com dans le but d'avoir les chiffres à la commune et une géométrie communale
-- Chiffres agrégés par commune : calcul des surfaces
-----------------------------------------------------------

-- Suppression de la table existante si elle existe déjà
-- Cela permet d'éviter des conflits si la table a déjà été créée auparavant
-- DROP TABLE IF EXISTS visufoncier.mos_foncier_agrege_com;

-- Création de la nouvelle table avec des données agrégées pour chaque commune
CREATE TABLE visufoncier.mos_foncier_agrege_com AS
SELECT
    -- Agrégation géométrique des communes : ST_Union fusionne les géométries et ST_Multi assure qu'elles soient de type MULTIPOLYGON
    ST_Multi(ST_Union(geom)) AS geom,

    -- Codes et noms des communes et autres niveaux administratifs
    insee_com,              -- Code INSEE de la commune
    nom_commune,            -- Nom de la commune
    nom_epci,               -- Nom de l'EPCI (Établissement Public de Coopération Intercommunale)
    insee_dep,              -- Code INSEE du département
    nom_scot,               -- Nom du SCOT (Schéma de Cohérence Territoriale)

    -- Calcul des surfaces agrégées
    ROUND(SUM(surface_calc_m2)::NUMERIC, 2) AS total_surface_calc_m2,  -- Surface totale calculée en m², arrondie à 2 décimales
    ROUND(SUM(surface_calc_ha)::NUMERIC, 2) AS total_surface_calc_ha,  -- Surface totale calculée en hectares, arrondie à 2 décimales

    -- Définition des dates de début et de fin de la période des données
    '2011-01-01 00:00:00'::TIMESTAMP AS millesime_debut,  -- Date de début des données (millesime initial)
    '2021-01-01 00:00:00'::TIMESTAMP AS millesime_fin    -- Date de fin des données (millesime final)

-- Source des données : table mos_foncier_agrege_2011_2021
FROM visufoncier.mos_foncier_agrege_2011_2021

-- Groupement des données par commune et autres niveaux administratifs
-- Cette étape permet d'agréger les données à l'échelle de chaque commune
GROUP BY insee_com, nom_commune, nom_epci, insee_dep, nom_scot;



-- Création d'un index spatial pour accélérer les requêtes géométriques (utilisation de GIST)
-- Cet index permet de rendre les opérations géographiques (comme ST_Within, ST_Intersects, etc.) plus rapides
CREATE INDEX IF NOT EXISTS idx_geom_mos_foncier_agrege_com 
ON visufoncier.mos_foncier_agrege_com 
USING GIST(geom);

-- Création d'un index sur les colonnes nom_epci, nom_commune et nom_scot
-- Cet index permet d'optimiser les requêtes qui filtrent ou trient sur ces colonnes
CREATE INDEX IF NOT EXISTS idx_nom_epci_commune_scot 
ON visufoncier.mos_foncier_agrege_com (nom_epci, nom_commune, nom_scot);

-- Ajout d'un commentaire descriptif sur la table pour la documentation
-- Cela aide à comprendre le but de la table lorsque d'autres utilisateurs consultent le schéma
COMMENT ON TABLE visufoncier.mos_foncier_agrege_com IS
  'Table du MOS avec les indicateurs agrégés par commune. Reliée au tableau de bord Superset';
  
--Ajout des droits GRANT SELECT (à personnaliser)
GRANT SELECT ON TABLE visufoncier.mos_foncier_agrege_com TO "";

-- Suppression des lignes où le code INSEE de la commune est NULL
-- Cela permet de nettoyer les données et éviter les erreurs liées aux enregistrements incomplets

DELETE FROM visufoncier.mos_foncier_agrege_com
WHERE insee_com IS NULL;


-- Ajout de la clé primaire sur la colonne insee_com
-- Cela permet d'assurer l'unicité des enregistrements par commune et améliore les performances des requêtes

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD PRIMARY KEY (insee_com);


-- Ajout de la colonne 'nom_departement' dans la table
-- Cette colonne sera remplie avec le nom du département basé sur le code INSEE de la commune
ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN nom_departement VARCHAR;


-- Mise à jour de la colonne 'nom_departement' en fonction du code INSEE des communes
-- Utilisation d'une instruction CASE pour affecter le nom du département en fonction du début du code INSEE
UPDATE visufoncier.mos_foncier_agrege_com
SET nom_departement = CASE
    WHEN LEFT(insee_com, 2) = '35' THEN 'Ille-et-Vilaine'    -- Département Ille-et-Vilaine
    WHEN LEFT(insee_com, 2) = '22' THEN 'Côtes-d''Armor'     -- Département Côtes-d'Armor
    WHEN LEFT(insee_com, 2) = '56' THEN 'Morbihan'           -- Département Morbihan
    WHEN LEFT(insee_com, 2) = '29' THEN 'Finistère'          -- Département Finistère
    ELSE 'Inconnu'                                           -- Optionnel : pour les communes dont le code INSEE ne correspond à aucun des départements définis
END;


-- Ajout de la colonne 'naf11art21' pour le code NAF (Nomenclature d'Activités Française) 11 article 21
-- Cette colonne contiendra des valeurs numériques pour l'agrégation des fichiers fonciers
ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN naf11art21 numeric(10,2);

-- Mise à jour de la colonne 'naf11art21' avec des données provenant de la table 'ff_obs_artif_conso_com'
-- La mise à jour est effectuée en fonction du code INSEE de la commune
-- Le calcul arrondit la valeur de 'naf11art21' à deux décimales et la divise par 10 000

UPDATE visufoncier.mos_foncier_agrege_com ma
SET naf11art21 = ROUND(fo.naf11art21 / 10000.0, 2)
FROM visufoncier.ff_obs_artif_conso_com fo
WHERE ma.insee_com = fo.idcom;


-- Ajout des colonnes pour la population de 2011 et 2021
-- pnum20 pour 2020 et pnum11 pour 2011

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN pnum20 NUMERIC,
ADD COLUMN pnum11 NUMERIC;

-- Mise à jour des colonnes pnum20 et pnum11 avec les données de population des communes
-- Les valeurs sont extraites de la table 'insee_popmun' et correspondantes aux codes INSEE des communes

UPDATE visufoncier.mos_foncier_agrege_com
SET pnum20 = visufoncier.insee_popmun.pmun2020::NUMERIC,
    pnum11 = visufoncier.insee_popmun.pmun2011::NUMERIC
FROM visufoncier.insee_popmun
WHERE visufoncier.mos_foncier_agrege_com.insee_com = visufoncier.insee_popmun.codgeo;


-- Ajout de la colonne 'diff_pop1120' pour calculer la différence entre la population de 2020 et celle de 2011

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN diff_pop1120 integer;


-- Mise à jour de la colonne 'diff_pop1120' avec la différence de population entre 2020 et 2011

UPDATE visufoncier.mos_foncier_agrege_com
SET diff_pop1120 = pnum20 - pnum11;


-- Ajout des colonnes pour la population de 2017 et 2018
-- pnum18 pour 2018 et pnum17 pour 2017

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN pnum18 NUMERIC,
ADD COLUMN pnum17 NUMERIC;


-- Mise à jour des colonnes pnum18 et pnum17 avec les données de population des communes
-- Les valeurs sont extraites de la table 'insee_popmun' pour les années 2018 et 2017

UPDATE visufoncier.mos_foncier_agrege_com
SET pnum18 = visufoncier.insee_popmun.pmun2018::NUMERIC,
    pnum17 = visufoncier.insee_popmun.pmun2017::NUMERIC
FROM visufoncier.insee_popmun
WHERE visufoncier.mos_foncier_agrege_com.insee_com = visufoncier.insee_popmun.codgeo;


-- Ajout des colonnes pour l'emploi de 2011 et 2021
-- p20_emplt pour 2020 et p11_emplt pour 2011

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN p20_emplt NUMERIC;

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN p11_emplt NUMERIC;


-- Mise à jour des colonnes p20_emplt et p11_emplt avec les données d'emploi pour 2020 et 2011
-- Les valeurs sont extraites des tables 'insee_emploi_2020' et 'insee_emploi_2011'

UPDATE visufoncier.mos_foncier_agrege_com AS f
SET p20_emplt = d."p20_emplt"
FROM visufoncier.insee_emploi_2020 AS d
WHERE f.insee_com = d."codgeo";

UPDATE visufoncier.mos_foncier_agrege_com AS f
SET p11_emplt = d."p11_emplt"
FROM visufoncier.insee_emploi_2011 AS d
WHERE f.insee_com = d."codgeo";


-- Ajout des colonnes pour l'emploi de 2018 et 2017
-- p18_emplt pour 2018 et p17_emplt pour 2017

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN p18_emplt NUMERIC;

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN p17_emplt NUMERIC;


-- Mise à jour des colonnes p18_emplt et p17_emplt avec les données d'emploi pour 2018 et 2017
-- Les valeurs sont extraites des tables 'insee_emploi_2018' et 'insee_emploi_2017'

UPDATE visufoncier.mos_foncier_agrege_com AS f
SET p18_emplt = d."p18_emplt"
FROM visufoncier.insee_emploi_2018 AS d
WHERE f.insee_com = d."codgeo";

UPDATE visufoncier.mos_foncier_agrege_com AS f
SET p17_emplt = d."p17_emplt"
FROM visufoncier.insee_emploi_2017 AS d
WHERE f.insee_com = d."codgeo";


-- Ajout des colonnes pour les ménages de 2011 et 2021
-- c11_men pour 2011 et c21_men pour 2021

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN c11_men NUMERIC;

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN c21_men NUMERIC;


-- Mise à jour des colonnes c11_men et c21_men avec les données de ménages pour 2011 et 2021
-- Les valeurs sont extraites des tables 'insee_menage_2011' et 'insee_menage_2021'

UPDATE visufoncier.mos_foncier_agrege_com AS f
SET c11_men = d."c11_men"
FROM visufoncier.insee_menage_2011 AS d
WHERE f.insee_com = d."codgeo";

UPDATE visufoncier.mos_foncier_agrege_com AS f
SET c21_men = d."c21_men"
FROM visufoncier.insee_menage_2021 AS d
WHERE f.insee_com = d."codgeo";


-- Ajout des colonnes pour les ménages de 2018 et 2017
-- c18_men pour 2018 et c17_men pour 2017

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN c18_men NUMERIC;

ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN c17_men NUMERIC;


-- Mise à jour des colonnes c18_men et c17_men avec les données de ménages pour 2018 et 2017
-- Les valeurs sont extraites des tables 'insee_menage_2018' et 'insee_menage_2017'

UPDATE visufoncier.mos_foncier_agrege_com AS f
SET c18_men = d."c18_men"
FROM visufoncier.insee_menage_2018 AS d
WHERE f.insee_com = d."codgeo";

UPDATE visufoncier.mos_foncier_agrege_com AS f
SET c17_men = d."c17_men"
FROM visufoncier.insee_menage_2017 AS d
WHERE f.insee_com = d."codgeo";



-- Consommation

-- Somme des surfaces consommées du MOS 2021 par commune
ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN surf_conso_2021 NUMERIC;


WITH summed_data AS (
    SELECT
        insee_com,
        SUM(surface_calc_ha) AS total_surface
    FROM
        visufoncier.mos_foncier_agrege
    WHERE
        enaf_conso_2021 = 'conso'
    GROUP BY
        insee_com
)
UPDATE visufoncier.mos_foncier_agrege_com mfa
SET surf_conso_2021 = sd.total_surface
FROM summed_data sd
WHERE mfa.insee_com = sd.insee_com;


-- Somme des surfaces consommées du MOS 2011 par commune
ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN surf_conso_2011 NUMERIC;


WITH summed_data AS (
    SELECT
        insee_com,
        SUM(surface_calc_ha) AS total_surface
    FROM
        visufoncier.mos_foncier_agrege
    WHERE
        enaf_conso_2011 = 'conso'
    GROUP BY
        insee_com
)
UPDATE visufoncier.mos_foncier_agrege_com mfa
SET surf_conso_2011 = sd.total_surface
FROM summed_data sd
WHERE mfa.insee_com = sd.insee_com;

  

-- Somme des ENAF du MOS 2021 par commune
ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN surf_enaf_2021 NUMERIC;


-- Étape 2 : Mettre à jour la colonne avec les valeurs calculées
WITH summed_data AS (
    SELECT
        insee_com,
        SUM(surface_calc_ha) AS total_surface
    FROM
        visufoncier.mos_foncier_agrege
    WHERE
        enaf_conso_2021 = 'enaf'
    GROUP BY
        insee_com
)
UPDATE visufoncier.mos_foncier_agrege_com mfa
SET surf_enaf_2021 = sd.total_surface
FROM summed_data sd
WHERE mfa.insee_com = sd.insee_com;


-- Somme des ENAF du MOS 2011 par commune


-- Étape 1 : Ajouter la colonne
ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN surf_enaf_2011 NUMERIC;


-- Étape 2 : Mettre à jour la colonne avec les valeurs calculées
WITH summed_data AS (
    SELECT
        insee_com,
        SUM(surface_calc_ha) AS total_surface
    FROM
        visufoncier.mos_foncier_agrege
    WHERE
        enaf_conso_2011 = 'enaf'
    GROUP BY
        insee_com
)
UPDATE visufoncier.mos_foncier_agrege_com mfa
SET surf_enaf_2011 = sd.total_surface
FROM summed_data sd
WHERE mfa.insee_com = sd.insee_com;

-- Flux renaturation hectare
ALTER TABLE visufoncier.mos_foncier_agrege_com
ADD COLUMN total_flux_renaturation NUMERIC(10,2);

WITH aggregated_data AS (
    SELECT 
        insee_com,
        SUM(surface_calc_ha) AS total_flux_renaturation
    FROM visufoncier.mos_foncier_agrege_2011_2021
    WHERE flux_renaturation = 1
    GROUP BY insee_com
)
UPDATE visufoncier.mos_foncier_agrege_com com
SET total_flux_renaturation = agg.total_flux_renaturation
FROM aggregated_data agg
WHERE com.insee_com = agg.insee_com;


--Adaptation de la syntaxe pour les prochaines vagues : il faudra étudier les impacts concernant le fait d'insérer des lignes (donc deux lignes par commune pour le prochain millesime) sur 
--les graphiques superset relié à mos_foncier_agrege_com : normalement la solution est le filtre sur le millesime
--sur la cartographie reliée à mos_foncier_agrege_com: car pour le moment on clique sur la commune et on a qu'une info, voir comment ça gère 2 informations ou + : Animation temporelle ? filtre ? deux cartos ? 

--Sinon refaire une table millésimée agrege_com, mais voir comment adapter les graphiques dans superset pour insérer les nouvelles données. 

--Exemple
-- Insertion des nouvelles données de mos_foncier_agrege_2021_2024 avec millesime_debut et millesime_fin mis à jour
--Attention à bien adapter le Millésime

INSERT INTO visufoncier.mos_foncier_agrege_com (geom, insee_com, nom_commune, nom_epci, insee_dep, nom_scot, total_surface_calc_m2, total_surface_calc_ha, millesime_debut, millesime_fin)
SELECT
    ST_Multi(ST_Union(geom)) AS geom,
    insee_com,
    nom_commune,
    nom_epci,
    insee_dep,
    nom_scot,
    ROUND(SUM(surface_calc_m2)::NUMERIC, 2) AS total_surface_calc_m2,
    ROUND(SUM(surface_calc_ha)::NUMERIC, 2) AS total_surface_calc_ha,
    '2021-01-01 00:00:00'::TIMESTAMP AS millesime_debut,  -- Millésime pour les nouvelles données
    '2024-01-01 00:00:00'::TIMESTAMP AS millesime_fin
FROM visufoncier.mos_foncier_agrege_2021_2024
GROUP BY insee_com, nom_commune, nom_epci, insee_dep, nom_scot;

--Puis adapter les updates ci dessus avec les nouvelles tables 
