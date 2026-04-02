
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Importation et traitement des différentes sources de données utiles pour le tableau de bord
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Téléchargement d'ADMIN EXPRESS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Afin de récupérer les informations géographiques telles que le SIREN et le nom de l'EPCI, du département, et de la commune, 
-- télécharger les données via la plateforme IGN : https://geoservices.ign.fr/adminexpress.

-- Tables à utiliser :
-- 1. Table des communes : "express_commune"
-- 2. Table des EPCI : "express_EPCI"

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remarques :
-- Si les tables existent déjà dans le schéma 'geobretagne', vérifier la date de mise à jour pour s'assurer qu'elles sont à jour.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Traitement des colonnes de la table des EPCI -- Mise à jour dec 2025 (ign.express_epci)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Si les données sont nouvellement chargées, renommer certaines colonnes pour correspondre aux standards utilisés dans le projet.


-- 1. Supprimer la contrainte PK actuelle sur id (si elle existe)
ALTER TABLE ign.express_epci_2025 DROP CONSTRAINT IF EXISTS express_epci_2025_pkey;

-- 2. Renommer les colonnes
ALTER TABLE ign.express_epci_2025 RENAME COLUMN id TO gid;
ALTER TABLE ign.express_epci_2025 RENAME COLUMN cleabs TO id;
ALTER TABLE ign.express_epci_2025 RENAME COLUMN code_siren TO code_epci;
ALTER TABLE ign.express_epci_2025 RENAME COLUMN nom_officiel TO nom_epci;
ALTER TABLE ign.express_epci_2025 RENAME COLUMN nature TO type_epci;

-- 3. Supprimer la colonne inutile
ALTER TABLE ign.express_epci_2025 DROP COLUMN nom_officiel_en_majuscules;

-- 4. Ajouter la clé primaire sur id (ancien cleabs)
ALTER TABLE ign.express_epci_2025 ADD PRIMARY KEY (id);

-- 5. Vérification
SELECT id, geom, fid, code_epci, nom_epci, type_epci
FROM ign.express_epci_2025
LIMIT 10;

-- 6. Optionnel : Renommer la table
ALTER TABLE ign.express_epci_2025 RENAME TO express_epci;



-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--INSEE : Historique de la population municipale par commune
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Objectif : Exécuter le fichier Python "syntaxe_insee_popmun_2022.py" dans un environnement virtuel (Envfoncier).
-- Ce script va lancer le téléchargement des données de population et générer un fichier propre en sortie. 
-- Remarque : Le script est calibré pour filtrer sur la Bretagne. Modifier la ligne suivante si nécessaire : df_filtered = df[df['reg'] == 53]

-- Objectif : Vérifier l'importation des données dans PostgreSQL.
-- La syntaxe Python doit importer les données dans la base de données PostgreSQL.

-- Pour vérifier l'importation des données, exécuter la requête suivante :
SELECT * FROM visufoncier.insee_popmun_2022;

--Supprimer les années précédentes si pas utile dans l'analyse
ALTER TABLE visufoncier.insee_popmun_2022
DROP COLUMN psdc1999,
DROP COLUMN psdc1990,
DROP COLUMN psdc1982,
DROP COLUMN psdc1975,
DROP COLUMN psdc1968,
DROP COLUMN psdc1962,
DROP COLUMN ptot1954,
DROP COLUMN ptot1936,
DROP COLUMN ptot1931,
DROP COLUMN ptot1926,
DROP COLUMN ptot1921,
DROP COLUMN ptot1911,
DROP COLUMN ptot1906,
DROP COLUMN ptot1901,
DROP COLUMN ptot1896,
DROP COLUMN ptot1891,
DROP COLUMN ptot1886,
DROP COLUMN ptot1881,
DROP COLUMN ptot1876;

--Commenter la table
COMMENT ON TABLE visufoncier.insee_insee_popmun_2022 IS
'Population municipale selon l''INSEE historique 1876-2021 par commune';

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INSEE : Chiffres de l'emploi année 2020 par commune (xlsx)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Objectif : Exécuter le fichier Python "syntaxe_insee_emploi_2022.py" dans un environnement virtuel (Envfoncier).
-- Ce script va lancer le téléchargement et générer un fichier propre en sortie.
-- Remarque : Le script est calibré pour filtrer sur la Bretagne. Modifier la ligne suivante si nécessaire : df_filtered_2020 = df_2020[df_2020['reg'] == 53]
-- Source des données : https://www.insee.fr/fr/statistiques/7632867?sommaire=7632977&q=Emploi+-%20population+active+en+2020

-- Le fichier CSV sera sauvegardé dans le dossier Téléchargements.
-- L'importation dans PostgreSQL est gérée via la syntaxe Python.

COMMENT ON TABLE visufoncier.insee_emploi_2022 IS
'Chiffres de l''emploi selon l''INSEE année 2020 par commune';


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--INSEE : Nombre de ménage en 2020 par commune
----------------------------------------------
--https://www.insee.fr/fr/statistiques/7633206?sommaire=7633255
--Dans un environnement virtuel (Envfoncier), exécuter le fichier python "syntaxe_insee_menage_2022.py"
--Cette syntaxe python va lancer le téléchargement et permet d'avoir un fichier propre en sortie. Attention, le script python est calibré pour filtrer sur la Bretagne. Ligne à modifier: df_filtered_2020 = df_2020[df_2020['reg'] == 53]

--L'import sous POSTGRESQL est géré via la syntaxe python


COMMENT ON TABLE visufoncier.insee_menage_2022 IS
'Nombre de ménage par commune selon l''INSEE historique 2020 par commune';


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Traitement des communes fusionnées 
-------------------------------------

-- Objectif : Additionner le nombre de ménage, d'emploi et de population pour les communes qui ont fusionnées (référence table fusion de commune "visufoncier.insee_fusioncom_2025"). 
--exemple : La Chapelle Janson (35062) et Fleurigné (35112) on fusionné en La chapelle Fleurigné. 
--Si la population était de 400 à La chapelle Janson et 200 à Fleurigné (chiffres fictifs), le résultat du traitement sera La Chapelle Fleurigné - 35062 - 600

--------------------
--Population 
--------------------
ALTER TABLE visufoncier.insee_popmun_2022
ADD COLUMN updated integer;

UPDATE visufoncier.insee_popmun_2022 AS vp
SET 
    updated = 1,
    codgeo = (SELECT vf.com_fin FROM visufoncier.insee_fusioncom_2025 AS vf WHERE vf.com_ini = vp.codgeo),
    libgeo = (SELECT vf.lib_com_fin FROM visufoncier.insee_fusioncom_2025 AS vf WHERE vf.com_ini = vp.codgeo)
WHERE EXISTS (
    SELECT 1 FROM visufoncier.insee_fusioncom_2025 AS vf 
    WHERE vf.com_ini = vp.codgeo AND vf.com_ini <> vf.com_fin
);

INSERT INTO visufoncier.insee_popmun_2022 (codgeo, reg, dep, libgeo)
SELECT 
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_popmun_2022
WHERE 
    updated = 1;

-- Étape 2: Mettre à jour les valeurs pmun dans une nouvelle ligne avec la somme des valeurs correspondant au même codgeo
UPDATE visufoncier.insee_popmun_2022 AS vp
SET 
	updated = 2, 
	   pmun2023 = (
        SELECT COALESCE(SUM(vp_inner.pmun2023), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
	   pmun2022 = (
        SELECT COALESCE(SUM(vp_inner.pmun2022), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2021 = (
        SELECT COALESCE(SUM(vp_inner.pmun2021), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2020 = (
        SELECT COALESCE(SUM(vp_inner.pmun2020), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2019 = (
        SELECT COALESCE(SUM(vp_inner.pmun2019), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2018 = (
        SELECT COALESCE(SUM(vp_inner.pmun2018), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2017 = (
        SELECT COALESCE(SUM(vp_inner.pmun2017), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2016 = (
        SELECT COALESCE(SUM(vp_inner.pmun2016), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2015 = (
        SELECT COALESCE(SUM(vp_inner.pmun2015), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2014 = (
        SELECT COALESCE(SUM(vp_inner.pmun2014), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2013 = (
        SELECT COALESCE(SUM(vp_inner.pmun2013), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2012 = (
        SELECT COALESCE(SUM(vp_inner.pmun2012), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2011 = (
        SELECT COALESCE(SUM(vp_inner.pmun2011), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2010 = (
        SELECT COALESCE(SUM(vp_inner.pmun2010), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2009 = (
        SELECT COALESCE(SUM(vp_inner.pmun2009), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2008 = (
        SELECT COALESCE(SUM(vp_inner.pmun2008), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2007 = (
        SELECT COALESCE(SUM(vp_inner.pmun2007), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2006 = (
        SELECT COALESCE(SUM(vp_inner.pmun2006), 0)
        FROM visufoncier.insee_popmun_2022 AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    )
FROM 
    visufoncier.insee_popmun_2022 AS vp_source
WHERE 
    vp.codgeo = vp_source.codgeo
    AND vp_source.updated = 1
    AND vp.pmun2022 IS NULL; -- Vérifie que les champs pmun2022 sont vides dans la nouvelle ligne

-- Étape 3: Supprimer les lignes ayant le même "codgeo" que les lignes où updated<>0, sauf celles où updated=0
DELETE FROM visufoncier.insee_popmun_2022 AS vp
WHERE updated = 1;

----------------
--Ménage 2022
----------------

ALTER TABLE visufoncier.insee_menage_2022
ADD COLUMN updated INTEGER;

UPDATE visufoncier.insee_menage_2022 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = ve.codgeo
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom_2025 AS vf 
    WHERE vf.com_ini = ve.codgeo 
      AND (vf.com_ini <> vf.com_fin )  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);

UPDATE visufoncier.insee_menage_2022 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom_2025 AS vf 
    WHERE vf.com_ini = ve.codgeo 
	AND ( vf.com_ini = vf.com_fin)
      AND ( vf.lib_com_ini <> vf.lib_com_fin)  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);
-- Insérer distinctement dans la table "visufoncier.insee_menage_2022" les enregistrements mis à jour
INSERT INTO visufoncier.insee_menage_2022 (codgeo, reg, dep, libgeo)
SELECT DISTINCT ON (codgeo)
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_menage_2022
WHERE 
    updated = 1;

-- Mettre à jour la colonne "updated" et le champ "c22_men" dans la table "visufoncier.insee_menage_2022"
UPDATE visufoncier.insee_menage_2022 AS im
SET 
    updated = 2,
    c22_men = (
        SELECT COALESCE(SUM(im_source.c22_men), 0)
        FROM visufoncier.insee_menage_2022 AS im_source
        WHERE im.codgeo = im_source.codgeo
    )
    FROM visufoncier.insee_menage_2022 AS im_source
    WHERE im.c22_men IS NULL 
      AND im_source.updated = 1;

-- Supprimer les enregistrements obsolètes de la table "visufoncier.insee_menage_2022"
DELETE FROM visufoncier.insee_menage_2022 AS im
 WHERE updated =1;


--------------
--Emploi 2022
--------------
ALTER TABLE visufoncier.insee_emploi_2022
ADD COLUMN updated INTEGER;

UPDATE visufoncier.insee_emploi_2022 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = ve.codgeo
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom_2025 AS vf 
    WHERE vf.com_ini = ve.codgeo 
      AND (vf.com_ini <> vf.com_fin )  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);

UPDATE visufoncier.insee_emploi_2022 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom_2025 AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom_2025 AS vf 
    WHERE vf.com_ini = ve.codgeo 
	AND ( vf.com_ini = vf.com_fin)
      AND ( vf.lib_com_ini <> vf.lib_com_fin)  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);

-- Insérer distinctement dans la table "visufoncier.insee_emploi_2022" les enregistrements mis à jour
INSERT INTO visufoncier.insee_emploi_2022 (codgeo, reg, dep, libgeo)
SELECT DISTINCT ON (codgeo)
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_emploi_2022
WHERE 
    updated = 1;

-- Mettre à jour la colonne "updated" et le champ "p22_emplt" dans la table "visufoncier.insee_emploi_2022"
UPDATE visufoncier.insee_emploi_2022 AS im
SET 
    updated = 2,
    p22_emplt = (
        SELECT COALESCE(SUM(im_source.p22_emplt), 0)
        FROM visufoncier.insee_emploi_2022 AS im_source
        WHERE im.codgeo = im_source.codgeo
    )
    FROM visufoncier.insee_emploi_2022 AS im_source
    WHERE im.p22_emplt IS NULL 
      AND im_source.updated = 1;

-- Supprimer les enregistrements obsolètes de la table "visufoncier.insee_emploi_2022"
DELETE FROM visufoncier.insee_emploi_2022 AS im
WHERE updated = 1;



------------------------------------------------------------------------------------------------------------------------------
-- CONSOLIDATION DONNÉES INSEE - TABLE UNIQUE AVEC FUSIONS APPLIQUÉES
------------------------------------------------------------------------------------------------------------------------------
-- Objectif : 
-- 1. Créer UNE table unique avec toutes les données INSEE (population, emploi, ménages)
-- 2. Appliquer TOUTES les fusions sur TOUTES les années (pour filtre Superset sur communes actuelles)
-- 3. Simplifier les jointures dans les vues matérialisées
------------------------------------------------------------------------------------------------------------------------------
-- IMPORTANT : Dans le dashboard, on filtre sur les communes ACTUELLES (ex: Lamballe-Armor)
-- Il faut donc agréger toutes les données historiques vers le code commune actuel
-- Exemple : Lamballe-Armor 2011 = Lamballe 2011 + Morieux 2011 + Planguenoual 2011
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
-- ÉTAPE 1 : CRÉATION TABLE CONSOLIDÉE INSEE
------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS visufoncier.insee_consolide CASCADE;

CREATE TABLE visufoncier.insee_consolide AS
WITH 
-- Liste des communes au référentiel FINAL (après toutes fusions)
communes_ref_final AS (
    SELECT DISTINCT 
        COALESCE(f.com_fin, p.codgeo) as insee_com,
        COALESCE(f.lib_com_fin, p.libgeo) as nom_commune
    FROM visufoncier.insee_popmun_2022 p
    LEFT JOIN visufoncier.insee_fusioncom_2025 f 
        ON p.codgeo = f.com_ini 
        AND f.annee_modif = (
            SELECT MAX(annee_modif) 
            FROM visufoncier.insee_fusioncom_2025 
            WHERE com_ini = p.codgeo
        )
),

-- POPULATION : Appliquer toutes les fusions sur toutes les années
pop_aggregee AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = p.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            p.codgeo
        ) as insee_com,
        SUM(p.pmun2011::numeric) as pnum2011,
        SUM(p.pmun2012::numeric) as pnum2012,
        SUM(p.pmun2013::numeric) as pnum2013,
        SUM(p.pmun2014::numeric) as pnum2014,
        SUM(p.pmun2015::numeric) as pnum2015,
        SUM(p.pmun2016::numeric) as pnum2016,
        SUM(p.pmun2017::numeric) as pnum2017,
        SUM(p.pmun2018::numeric) as pnum2018,
        SUM(p.pmun2019::numeric) as pnum2019,
        SUM(p.pmun2020::numeric) as pnum2020,
        SUM(p.pmun2021::numeric) as pnum2021,
        SUM(p.pmun2022::numeric) as pnum2022,
        SUM(p.pmun2023::numeric) as pnum2023
    FROM visufoncier.insee_popmun_2022 p
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = p.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        p.codgeo
    )
),

-- EMPLOI : Toutes fusions appliquées
emploi_2011 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = e.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            e.codgeo
        ) as insee_com,
        SUM(e.p11_emplt::numeric) as p11_emplt
    FROM visufoncier.insee_emploi_2011 e
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = e.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        e.codgeo
    )
),
emploi_2017 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = e.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            e.codgeo
        ) as insee_com,
        SUM(e.p17_emplt::numeric) as p17_emplt
    FROM visufoncier.insee_emploi_2017 e
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = e.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        e.codgeo
    )
),
emploi_2018 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = e.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            e.codgeo
        ) as insee_com,
        SUM(e.p18_emplt::numeric) as p18_emplt
    FROM visufoncier.insee_emploi_2018 e
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = e.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        e.codgeo
    )
),
emploi_2020 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = e.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            e.codgeo
        ) as insee_com,
        SUM(e.p20_emplt::numeric) as p20_emplt
    FROM visufoncier.insee_emploi_2020 e
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = e.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        e.codgeo
    )
),
emploi_2022 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = e.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            e.codgeo
        ) as insee_com,
        SUM(e.p22_emplt::numeric) as p22_emplt
    FROM visufoncier.insee_emploi_2022 e
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = e.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        e.codgeo
    )
),

-- MÉNAGES : Toutes fusions appliquées
menage_2011 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = m.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            m.codgeo
        ) as insee_com,
        SUM(m.c11_men::numeric) as c11_men
    FROM visufoncier.insee_menage_2011 m
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = m.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        m.codgeo
    )
),
menage_2017 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = m.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            m.codgeo
        ) as insee_com,
        SUM(m.c17_men::numeric) as c17_men
    FROM visufoncier.insee_menage_2017 m
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = m.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        m.codgeo
    )
),
menage_2018 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = m.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            m.codgeo
        ) as insee_com,
        SUM(m.c18_men::numeric) as c18_men
    FROM visufoncier.insee_menage_2018 m
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = m.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        m.codgeo
    )
),
menage_2019 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = m.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            m.codgeo
        ) as insee_com,
        SUM(m.c19_men::numeric) as c19_men
    FROM visufoncier.insee_menage_2019 m
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = m.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        m.codgeo
    )
),
menage_2020 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = m.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            m.codgeo
        ) as insee_com,
        SUM(m.c20_men::numeric) as c20_men
    FROM visufoncier.insee_menage_2020 m
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = m.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        m.codgeo
    )
),
menage_2022 AS (
    SELECT 
        COALESCE(
            (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
             WHERE com_ini = m.codgeo 
             ORDER BY annee_modif DESC LIMIT 1), 
            m.codgeo
        ) as insee_com,
        SUM(m.c22_men::numeric) as c22_men
    FROM visufoncier.insee_menage_2022 m
    GROUP BY COALESCE(
        (SELECT com_fin FROM visufoncier.insee_fusioncom_2025 
         WHERE com_ini = m.codgeo 
         ORDER BY annee_modif DESC LIMIT 1), 
        m.codgeo
    )
)
-- Assemblage final
SELECT 
    c.insee_com,
    c.nom_commune,
    -- Population
    p.pnum2011, p.pnum2012, p.pnum2013, p.pnum2014, p.pnum2015,
    p.pnum2016, p.pnum2017, p.pnum2018, p.pnum2019, p.pnum2020,
    p.pnum2021, p.pnum2022, p.pnum2023,
    -- Emploi
    e11.p11_emplt, e17.p17_emplt, e18.p18_emplt, e20.p20_emplt, e22.p22_emplt,
    -- Ménages
    m11.c11_men, m17.c17_men, m18.c18_men, m19.c19_men, m20.c20_men, m22.c22_men
FROM communes_ref_final c
LEFT JOIN pop_aggregee p ON c.insee_com = p.insee_com
LEFT JOIN emploi_2011 e11 ON c.insee_com = e11.insee_com
LEFT JOIN emploi_2017 e17 ON c.insee_com = e17.insee_com
LEFT JOIN emploi_2018 e18 ON c.insee_com = e18.insee_com
LEFT JOIN emploi_2020 e20 ON c.insee_com = e20.insee_com
LEFT JOIN emploi_2022 e22 ON c.insee_com = e22.insee_com
LEFT JOIN menage_2011 m11 ON c.insee_com = m11.insee_com
LEFT JOIN menage_2017 m17 ON c.insee_com = m17.insee_com
LEFT JOIN menage_2018 m18 ON c.insee_com = m18.insee_com
LEFT JOIN menage_2019 m19 ON c.insee_com = m19.insee_com
LEFT JOIN menage_2020 m20 ON c.insee_com = m20.insee_com
LEFT JOIN menage_2022 m22 ON c.insee_com = m22.insee_com;

-- Clé primaire
ALTER TABLE visufoncier.insee_consolide ADD PRIMARY KEY (insee_com);

-- Index
CREATE INDEX idx_insee_consolide_nom ON visufoncier.insee_consolide (nom_commune);

-- Commentaire
COMMENT ON TABLE visufoncier.insee_consolide IS
'Table consolidée INSEE avec toutes les données (pop, emploi, ménages) et fusions de communes 2025 appliquées sur toutes les années.';

-- Droits
GRANT SELECT ON TABLE visufoncier.insee_consolide TO "app-visufoncier";
GRANT ALL ON TABLE visufoncier.insee_consolide TO "margot.leborgne";
GRANT SELECT ON TABLE visufoncier.insee_consolide TO "www-data";


------------------------------------------------------------------------------------------------------------------------------
-- ÉTAPE 2 : VÉRIFICATION - Exemples Merdrignac et Lamballe-Armor
------------------------------------------------------------------------------------------------------------------------------

-- Vérifier Lamballe-Armor (fusion 2019 : Lamballe + Morieux + Planguenoual)
SELECT 
    insee_com,
    nom_commune,
    p11_emplt as emploi_2011,  
    p17_emplt as emploi_2017,  
    p20_emplt as emploi_2020,  
    p22_emplt as emploi_2022,  
    pnum2011 as pop_2011,  
    pnum2018 as pop_2018,
    pnum2020 as pop_2020,
    pnum2022 as pop_2022
FROM visufoncier.insee_consolide
WHERE insee_com = '22093';  -- Code Lamballe-Armor

-- Résultat attendu pour Lamballe-Armor (22093) :
-- p11_emplt = emploi Lamballe + Morieux + Planguenoual (SOMME des 3)
-- p17_emplt = emploi Lamballe + Morieux + Planguenoual (SOMME des 3)
-- p20_emplt = emploi Lamballe + Morieux + Planguenoual (SOMME des 3)
-- pnum2011 = population Lamballe + Morieux + Planguenoual (SOMME des 3)
-- → Comme ça, quand on filtre sur "Lamballe-Armor" dans Superset, on a les données de 2011 !


-- Vérifier Merdrignac (fusion 2025 avec Saint-Launeuc)
SELECT 
    insee_com,
    nom_commune,
    p20_emplt as emploi_2020,
    p22_emplt as emploi_2022,
    pnum2020 as population_2020,
    pnum2022 as population_2022
FROM visufoncier.insee_consolide
WHERE insee_com = '22147';  -- Code Merdrignac

-- Résultat attendu pour Merdrignac :
-- p20_emplt = emploi Merdrignac + Saint-Launeuc (1457.86 + 45.17 = 1503.03)
-- p22_emplt = emploi Merdrignac + Saint-Launeuc


-- Vérifier qu'on a bien UNE SEULE ligne par commune (référentiel final)
SELECT COUNT(*) as nb_communes FROM visufoncier.insee_consolide;
-- Doit correspondre au nombre de communes actuelles après toutes fusions
