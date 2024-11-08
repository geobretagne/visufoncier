----------------------------------------------------------------------------------------------------------------------------------------------------
--Traitement des tables OCS GE NG "diff" afin de calculer les flux d'artificilisation entre le début et la fin des millésimes selon les départements 
----------------------------------------------------------------------------------------------------------------------------------------------------

--Objectif : croiser les tables "diff" avec express_commune et pci_vecteur pour retrouver les codes insee puis calculer les flux d'artif
--une table par département 


--A partir des tables brutes, creer une table pour chaque département en modifiant _xx et _anneefin et _anneedebut pour le début et la fin d'analyse (ex pour le 35, anneedebut 2017 et anneefin 2020

CREATE TABLE visufoncier.ocsge_xx_diff AS
WITH numbered_data AS (
    SELECT
        o.id_anneefin AS id_fin_origine, 
        o.id_anneedebut AS id_deb_origine,  -- Conserver l'ancien ID
        ROW_NUMBER() OVER () AS id,  -- Générer un nouvel ID unique
        o.cs_anneefin as cs_fin,
        o.us_anneefin as us_fin,
        o.cs_anneedebut as cs_debut,
        o.us_anneedebut as us_debut,
        c.nom AS nom_commune,
        c.insee_com,
        c.siren_epci,
        c.insee_dep,
        c.insee_reg,
        ST_SetSRID(ST_Multi(COALESCE(ST_Intersection(o.geom, c.geom), o.geom)), 2154) AS geom
    FROM
        ocsge.ocsge_xx_diff_anneefin_anneedebut o
    LEFT JOIN
        ign.express_commune c 
    ON
        ST_Intersects(o.geom, c.geom)
    WHERE
        ST_IsValid(o.geom)
        AND (c.insee_com IS NULL OR c.insee_com LIKE 'xx%')  -- adapter la syntaxe
)
SELECT
    id_fin_origine,
    id_deb_origine,
    id,
    cs_fin,
    us_fin,
    cs_debut,
    us_debut,
    CASE WHEN insee_com IS NOT NULL THEN nom_commune ELSE NULL END AS nom_commune,
    CASE WHEN insee_com IS NOT NULL THEN insee_com ELSE NULL END AS insee_com,
    CASE WHEN insee_com IS NOT NULL THEN siren_epci ELSE NULL END AS siren_epci,
    CASE WHEN insee_com IS NOT NULL THEN insee_dep ELSE NULL END AS insee_dep,
    CASE WHEN insee_com IS NOT NULL THEN insee_reg ELSE NULL END AS insee_reg,
    geom
FROM
    numbered_data;


--Vérifier que tout est bien déclaré en multipolygon 2154. iL ne faut pas de 0 en srid
SELECT Find_SRID('visufoncier', 'ocsge_xx_diff', 'geom'), GeometryType(geom) 
FROM visufoncier.ocsge_xx_diff
LIMIT 1;

ALTER TABLE visufoncier.ocsge_xx_diff
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);

--relancer le select pour voir si c'est bon

--Definir une clé primaire
ALTER TABLE visufoncier.ocsge_xx_diff
ADD CONSTRAINT ocsge_xx_diff_brut_pkey PRIMARY KEY (id);


---------------------------------------------------------
-- aller chercher les insee_com manquant dans pci vecteur 
------------------------------------------------------------

WITH cadastre_update AS (
    SELECT
        o.id,
        COALESCE(ST_Intersection(o.geom, cad.geom), o.geom) AS geom,  -- Intersection avec le cadastre ou géométrie originale si rien
        (cad.dep || cad.idu) AS insee_com,  -- Concaténation de 'dep' et 'idu' pour former 'insee_com'
        cad.tex2 AS nom_commune  -- Utilise nom_commune du cadastre directement
    FROM
        visufoncier.ocsge_xx_diff o
    LEFT JOIN
        pci.cadastre_commune_2023 cad 
    ON
        ST_Intersects(o.geom, cad.geom)  -- Intersection avec le cadastre
    WHERE
        o.insee_com IS NULL  -- Ne traite que les lignes sans insee_com
        AND ST_IsValid(o.geom)  -- Filtre les géométries valides
        AND cad.dep = '35'  -- Filtre uniquement pour le département 35
)
UPDATE visufoncier.ocsge_xx_diff o
SET
    geom = ST_Multi(cadastre_update.geom),  -- Forcer la géométrie à être multipolygone
    insee_com = cadastre_update.insee_com,  -- Mise à jour de insee_com depuis cadastre (concaténation de 'dep' et 'idu')
    nom_commune = cadastre_update.nom_commune  -- Mise à jour de nom_commune depuis cadastre
FROM
    cadastre_update
WHERE
    o.id = cadastre_update.id;  -- Mise à jour des lignes correspondantes par id

    
    -- Rappatrier les bons noms de commune et le département, siren epci..
UPDATE visufoncier.ocsge_xx_diff o
SET
    nom_commune = c.nom,  -- Mise à jour du nom de la commune
    siren_epci = c.siren_epci,  -- Mise à jour du champ siren_epci
    insee_dep = c.insee_dep,  -- Mise à jour du champ insee_dep
    insee_reg = c.insee_reg  -- Mise à jour du champ insee_reg
FROM
    ign.express_commune c
WHERE
    o.insee_com = c.insee_com  -- Correspondance avec la table express_commune
    AND (o.siren_epci IS NULL OR o.siren_epci = '');  -- Mettre à jour seulement si siren_epci est manquant ou vide

 -------------------------------------
 --calcul des variables artif de fin
 -------------------------------------
  
----ajout attributs artif_fin/non artif_fin dans ocs ge 
alter table visufoncier.ocsge_xx_diff add column artif_fin character varying(10);

---artificialisé en raison du bâti
update visufoncier.ocsge_xx_diff  set artif_fin='artif' where cs_fin='CS1.1.1.1';

---artificialisé autre
update visufoncier.ocsge_xx_diff 
set artif_fin='artif'
where
artif_fin is null and
(
(cs_fin='CS1.1.1.2' or cs_fin='CS1.1.2.2') or (cs_fin = 'CS1.1.2.1' AND NOT us_fin
= 'US1.3')
or
((cs_fin like 'CS2.2%') AND (us_fin = 'US2'OR us_fin = 'US3' OR us_fin = 'US5'
OR us_fin = 'US235' OR us_fin like 'US4%' OR us_fin = 'US6.1' OR us_fin = 'US6.2'
)));

--non artificialisé
update visufoncier.ocsge_xx_diff  set artif_fin='non artif' where artif_fin is null;

-------------------------------------
--calcul des variables artif de début
-------------------------------------

----ajout attributs artif_debut/non artif_debut dans ocs ge 
alter table visufoncier.ocsge_xx_diff add column artif_debut character varying(10);

---artificialisé en raison du bâti
update visufoncier.ocsge_xx_diff  set artif_debut='artif' where cs_debut='CS1.1.1.1';

---artificialisé autre
update visufoncier.ocsge_xx_diff 
set artif_debut='artif'
where
artif_debut is null and
(
(cs_debut='CS1.1.1.2' or cs_debut='CS1.1.2.2') or (cs_debut = 'CS1.1.2.1' AND NOT us_debut
= 'US1.3')
or
((cs_debut like 'CS2.2%') AND (us_debut = 'US2'OR us_debut = 'US3' OR us_debut = 'US5'
OR us_debut = 'US235' OR us_debut like 'US4%' OR us_debut = 'US6.1' OR us_debut = 'US6.2'
)));

--non artificialisé
update visufoncier.ocsge_xx_diff  set artif_debut='non artif' where artif_debut is null;

CREATE INDEX idx_ocsge_xx_diff_artif_anneefin ON visufoncier.ocsge_xx_diff (artif_fin); -- à adapter
CREATE INDEX idx_ocsge_xx_diff_artif_annee_debut ON visufoncier.ocsge_xx_diff (artif_debut); -- à adapter
-------------------------------------
--Calcul des millesime et de surface
--------------------------------------

   --Millesime
ALTER TABLE visufoncier.ocsge_xx_diff 
ADD COLUMN millesime_debut TIMESTAMP;

UPDATE visufoncier.ocsge_xx_diff 
SET millesime_debut = 'anneedebut-01-01 00:00:00'; -- à adapter

   --Millesime
ALTER TABLE visufoncier.ocsge_xx_diff 
ADD COLUMN millesime_fin TIMESTAMP;

UPDATE visufoncier.ocsge_xx_diff 
SET millesime_fin = 'anneefin-01-01 00:00:00'; -- à adapter

 --Calcul de surface
 
ALTER TABLE visufoncier.ocsge_xx_diff 
ADD COLUMN surface_m2 FLOAT8,
ADD COLUMN surface_ha FLOAT8;

UPDATE visufoncier.ocsge_xx_diff 
SET 
    surface_m2 = ST_Area(geom),
    surface_ha = ST_Area(geom) / 10000;



   -----------------
 -----EPCI  SCOT DEPT
   -----------------
   
   
--Ajouter une colonne nom_scot
ALTER TABLE visufoncier.ocsge_xx_diff
ADD COLUMN nom_scot VARCHAR(255);

UPDATE visufoncier.ocsge_xx_diff v
SET nom_scot = s.nom_scot
FROM visufoncier.ocsge_xx_anneefin_brut s
WHERE v.insee_com = s.insee_com;
   
ALTER TABLE visufoncier.ocsge_xx_diff
ADD COLUMN nom_epci VARCHAR(255);

UPDATE visufoncier.ocsge_xx_diff v
SET nom_epci = s.nom_epci
FROM visufoncier.ocsge_xx_anneefin_brut s
WHERE v.insee_com = s.insee_com;

ALTER TABLE visufoncier.ocsge_xx_diff
ADD COLUMN nom_departement VARCHAR(255);

UPDATE visufoncier.ocsge_xx_diff v
SET nom_departement = s.nom_departement
FROM visufoncier.ocsge_xx_anneefin_brut s
WHERE v.insee_com = s.insee_com;


--Commentaires sur les TABLES

COMMENT ON TABLE visufoncier.ocsge_xx_diff IS 'Table qui intersecte les données brutes de l''OCS GE NG à partir des tables de différence par département pour le calcul des flux d''artificialisation. Intersecte avec admin express et PCI vecteur pour retrouver le code INSEE. Table principale pour l''analyse des flux d''artificialisation par département.';



----------------------------------------------------------------------------
 --Creer une table avec tous les département - Table union des départements
------------------------------------------------------------------------------

--exemple de syntaxe d'union sur 3 départements (à adapter) 

CREATE TABLE visufoncier.ocsge_diff AS
SELECT 
    id,
    cs_fin::varchar(50),     -- Assure que tous les types de colonne correspondent
    us_fin::varchar(50),
    cs_debut::varchar(50),
    us_debut::varchar(50),
    nom_commune,
    insee_com,
    nom_epci,
    nom_departement,
    nom_scot,
    geom,
    artif_fin,
    artif_debut,
    millesime_debut,
    millesime_fin,
    surface_m2,
    surface_ha
FROM visufoncier.ocsge_xx_diff

UNION ALL

SELECT 
    id,
    cs_fin::varchar(50),
    us_fin::varchar(50),
    cs_debut::varchar(50),
    us_debut::varchar(50),
    nom_commune,
    insee_com,
    nom_epci,
    nom_departement,
    nom_scot,
    geom,
    artif_fin,
    artif_debut,
    millesime_debut,
    millesime_fin,
    surface_m2,
    surface_ha
FROM visufoncier.ocsge_xx_diff

UNION ALL

SELECT 
    id,
    cs_fin::varchar(50),     
    us_fin::varchar(50),
    cs_debut::varchar(50),
    us_debut::varchar(50),
    nom_commune,
    insee_com,
    nom_epci,
    nom_departement,
    nom_scot,
    geom,
    artif_fin,
    artif_debut,
    millesime_debut,
    millesime_fin,
    surface_m2,
    surface_ha
FROM visufoncier.ocsge_xx_diff;


--Commentaire
COMMENT ON TABLE visufoncier.ocsge_diff IS 'Union des tables de l''OCS GE NG diff pour le calcul des flux d''artificialisation entre le millésime début et le millésime fin.';



----------------------------------------------------------------
--Ajout des codes us cs regroupés dans la table unifiée par département 
----------------------------------------------------------------

--Regroupement des codes CS


ALTER table visufoncier.ocsge_diff
ADD COLUMN cs_regroup1_fin TEXT;

UPDATE visufoncier.ocsge_diff
SET cs_regroup1_fin = CASE 
    -- Catégories sans végétation (CS1)
    WHEN cs_fin IN ('CS1.1.1.1', 'CS1.1.1.2') THEN 'CS1.1.1 Zones imperméables'
    WHEN cs_fin IN ('CS1.1.2.1', 'CS1.1.2.2') THEN 'CS1.1.2 Zones perméables'
    WHEN cs_fin IN ('CS1.2.1', 'CS1.2.2', 'CS1.2.3') THEN 'CS1.2 Surfaces naturelles'

    -- Catégories avec végétation (CS2)
    WHEN cs_fin IN ('CS2.1.1.1', 'CS2.1.1.2', 'CS2.1.1.3') THEN 'CS2.1.1 Formations arborées'
    WHEN cs_fin = 'CS2.1.2' THEN 'CS2.1.2 Formations arbustives et sous-arbrisseaux (Landes basses, formations arbustives organisées, …)'
    WHEN cs_fin = 'CS2.1.3' THEN 'CS2.1.3 Autres formations ligneuses (Vignes et autres lianes)'
    WHEN cs_fin = 'CS2.2.1' THEN 'CS2.2.1 Formations herbacées (Pelouses, prairies, terres arables, roselières, …)'
    WHEN cs_fin = 'CS2.2.2' THEN 'CS2.2.2 Autres formations non ligneuses (Lichen, mousse, bananiers, bambous, …)'
    ELSE 'Inconnu'
END;

ALTER table visufoncier.ocsge_diff
ADD COLUMN cs_regroup1_debut TEXT;

UPDATE visufoncier.ocsge_diff
SET cs_regroup1_debut = CASE 
    -- Catégories sans végétation (CS1)
    WHEN cs_debut IN ('CS1.1.1.1', 'CS1.1.1.2') THEN 'CS1.1.1 Zones imperméables'
    WHEN cs_debut IN ('CS1.1.2.1', 'CS1.1.2.2') THEN 'CS1.1.2 Zones perméables'
    WHEN cs_debut IN ('CS1.2.1', 'CS1.2.2', 'CS1.2.3') THEN 'CS1.2 Surfaces naturelles'

    -- Catégories avec végétation (CS2)
    WHEN cs_debut IN ('CS2.1.1.1', 'CS2.1.1.2', 'CS2.1.1.3') THEN 'CS2.1.1 Formations arborées'
    WHEN cs_debut = 'CS2.1.2' THEN 'CS2.1.2 Formations arbustives et sous-arbrisseaux (Landes basses, formations arbustives organisées, …)'
    WHEN cs_debut = 'CS2.1.3' THEN 'CS2.1.3 Autres formations ligneuses (Vignes et autres lianes)'
    WHEN cs_debut = 'CS2.2.1' THEN 'CS2.2.1 Formations herbacées (Pelouses, prairies, terres arables, roselières, …)'
    WHEN cs_debut = 'CS2.2.2' THEN 'CS2.2.2 Autres formations non ligneuses (Lichen, mousse, bananiers, bambous, …)'
    ELSE 'Inconnu'
END;



ALTER TABLE visufoncier.ocsge_diff
ADD COLUMN cs_regroup2_fin TEXT;

UPDATE visufoncier.ocsge_diff
SET cs_regroup2_fin = CASE 
    -- Catégories sans végétation (CS1)
    WHEN cs_fin IN ('CS1.1.1.1', 'CS1.1.1.2', 'CS1.1.2.1', 'CS1.1.2.2') THEN 'CS1.1 Surface anthropisées'
    
    --Surface naturelles
    WHEN cs_fin IN ('CS1.2.1', 'CS1.2.2', 'CS1.2.3') THEN 'CS1.2 Surfaces naturelles'

    -- Catégories avec végétation (CS2)
    WHEN cs_fin IN ('CS2.1.1.1', 'CS2.1.1.2', 'CS2.1.1.3','CS2.1.2','CS2.1.3') THEN 'CS2.1 Végétation ligneuse'
    WHEN cs_fin IN ('CS2.2.1','CS2.2.2') THEN 'CS2.2 Végétation non ligneuse'
    ELSE 'Inconnu'
END;

ALTER TABLE visufoncier.ocsge_diff
ADD COLUMN cs_regroup2_debut TEXT;

UPDATE visufoncier.ocsge_diff
SET cs_regroup2_debut = CASE 
    -- Catégories sans végétation (CS1)
    WHEN cs_debut IN ('CS1.1.1.1', 'CS1.1.1.2', 'CS1.1.2.1', 'CS1.1.2.2') THEN 'CS1.1 Surface anthropisées'
    
    --Surface naturelles
    WHEN cs_debut IN ('CS1.2.1', 'CS1.2.2', 'CS1.2.3') THEN 'CS1.2 Surfaces naturelles'

    -- Catégories avec végétation (CS2)
    WHEN cs_debut IN ('CS2.1.1.1', 'CS2.1.1.2', 'CS2.1.1.3','CS2.1.2','CS2.1.3') THEN 'CS2.1 Végétation ligneuse'
    WHEN cs_debut IN ('CS2.2.1','CS2.2.2') THEN 'CS2.2 Végétation non ligneuse'
    ELSE 'Inconnu'
END;

ALTER TABLE visufoncier.ocsge_diff
ADD COLUMN cs_regroup3_fin TEXT;

UPDATE visufoncier.ocsge_diff
SET cs_regroup3_fin = CASE 
    -- Catégories sans végétation (CS1)
    WHEN cs_fin IN ('CS1.1.1.1', 'CS1.1.1.2', 'CS1.1.2.1', 'CS1.1.2.2', 'CS1.2.1', 'CS1.2.2', 'CS1.2.3') THEN 'CS1 Sans végétation'
    -- Catégories avec végétation (CS2)
    WHEN cs_fin IN ('CS2.1.1.1', 'CS2.1.1.2', 'CS2.1.1.3','CS2.1.2','CS2.1.3','CS2.2.1','CS2.2.2') THEN 'CS2 Avec végétation'
    ELSE 'Inconnu'
END;

ALTER TABLE visufoncier.ocsge_diff
ADD COLUMN cs_regroup3_debut TEXT;

UPDATE visufoncier.ocsge_diff
SET cs_regroup3_debut = CASE 
    -- Catégories sans végétation (CS1)
    WHEN cs_debut IN ('CS1.1.1.1', 'CS1.1.1.2', 'CS1.1.2.1', 'CS1.1.2.2', 'CS1.2.1', 'CS1.2.2', 'CS1.2.3') THEN 'CS1 Sans végétation'
    -- Catégories avec végétation (CS2)
    WHEN cs_debut IN ('CS2.1.1.1', 'CS2.1.1.2', 'CS2.1.1.3','CS2.1.2','CS2.1.3','CS2.2.1','CS2.2.2') THEN 'CS2 Avec végétation'
    ELSE 'Inconnu'
END;

--regroupement code US

ALTER TABLE visufoncier.ocsge_diff 
ADD COLUMN us_regroup1_fin TEXT;

UPDATE visufoncier.ocsge_diff 
SET us_regroup1_fin = CASE 
    -- Production primaire (US1)
    WHEN us_fin LIKE 'US1%' THEN 'US1 Production primaire'

    -- Production secondaire, tertiaire et usage résidentiel (US235)
    WHEN us_fin IN ('US2', 'US3', 'US5', 'US235') THEN 'US235 Production secondaire, tertiaire et usage résidentiel'

    -- Réseaux de transport et utilité publique (US4)
    WHEN us_fin LIKE 'US4%' THEN 'US4 Réseaux de transport logistiques et infrastructures'

    -- Autres usages (US6)
    WHEN us_fin LIKE 'US6%' THEN 'US6 Autres usages'

    ELSE 'Inconnu'
END;


ALTER TABLE visufoncier.ocsge_diff 
ADD COLUMN us_regroup1_debut TEXT;

UPDATE visufoncier.ocsge_diff 
SET us_regroup1_debut = CASE 
    -- Production primaire (US1)
    WHEN us_debut LIKE 'US1%' THEN 'US1 Production primaire'

    -- Production secondaire, tertiaire et usage résidentiel (US235)
    WHEN us_debut IN ('US2', 'US3', 'US5', 'US235') THEN 'US235 Production secondaire, tertiaire et usage résidentiel'

    -- Réseaux de transport et utilité publique (US4)
    WHEN us_debut LIKE 'US4%' THEN 'US4 Réseaux de transport logistiques et infrastructures'

    -- Autres usages (US6)
    WHEN us_debut LIKE 'US6%' THEN 'US6 Autres usages'

    ELSE 'Inconnu'
END;



ALTER TABLE visufoncier.ocsge_diff 
ADD COLUMN cs_debut_lib TEXT;

UPDATE visufoncier.ocsge_diff 
SET cs_debut_lib = CASE 
    WHEN cs_debut = 'CS1.1.1.1' THEN 'CS1.1.1.1 Zones bâties'
    WHEN cs_debut = 'CS1.1.1.2' THEN 'CS1.1.1.2 Zones non bâties (Routes, places, parking...)'
    WHEN cs_debut = 'CS1.1.2.1' THEN 'CS1.1.2.1 Zones à matériaux minéraux'
    WHEN cs_debut = 'CS1.1.2.2' THEN 'CS1.1.2.2 Zones à autres matériaux composites'
    WHEN cs_debut = 'CS1.2.1' THEN 'CS1.2.1 Sols nus (Sable, pierres meubles, rochers saillants, …)'
    WHEN cs_debut = 'CS1.2.2' THEN 'CS1.2.2 Surfaces d''eau (Eau continentale et maritime)'
    WHEN cs_debut = 'CS1.2.3' THEN 'CS1.2.3 Névés et glaciers'
    WHEN cs_debut = 'CS2.1.1.1' THEN 'CS2.1.1.1 Peuplement de feuillus'
    WHEN cs_debut = 'CS2.1.1.2' THEN 'CS2.1.1.2 Peuplement de conifères'
    WHEN cs_debut = 'CS2.1.1.3' THEN 'CS2.1.1.3 Peuplement mixte'
    WHEN cs_debut = 'CS2.1.2' THEN 'CS2.1.2 Formations arbustives et sous-arbrisseaux (Landes basses, formations arbustives organisées, …)'
    WHEN cs_debut = 'CS2.1.3' THEN 'CS2.1.3 Autres formations ligneuses (Vignes et autres lianes)'
    WHEN cs_debut = 'CS2.2.1' THEN 'CS2.2.1 Formations herbacées (Pelouses, prairies, terres arables, roselières, …)'
    WHEN cs_debut = 'CS2.2.2' THEN 'CS2.2.2 Autres formations non ligneuses (Lichen, mousse, bananiers, bambous, …)'
    ELSE 'Code inconnu'
END;

ALTER TABLE visufoncier.ocsge_diff 
ADD COLUMN cs_fin_lib TEXT;

UPDATE visufoncier.ocsge_diff 
SET cs_fin_lib = CASE 
    WHEN cs_fin = 'CS1.1.1.1' THEN 'CS1.1.1.1 Zones bâties'
    WHEN cs_fin = 'CS1.1.1.2' THEN 'CS1.1.1.2 Zones non bâties (Routes, places, parking...)'
    WHEN cs_fin = 'CS1.1.2.1' THEN 'CS1.1.2.1 Zones à matériaux minéraux'
    WHEN cs_fin = 'CS1.1.2.2' THEN 'CS1.1.2.2 Zones à autres matériaux composites'
    WHEN cs_fin = 'CS1.2.1' THEN 'CS1.2.1 Sols nus (Sable, pierres meubles, rochers saillants, …)'
    WHEN cs_fin = 'CS1.2.2' THEN 'CS1.2.2 Surfaces d''eau (Eau continentale et maritime)'
    WHEN cs_fin = 'CS1.2.3' THEN 'CS1.2.3 Névés et glaciers'
    WHEN cs_fin = 'CS2.1.1.1' THEN 'CS2.1.1.1 Peuplement de feuillus'
    WHEN cs_fin = 'CS2.1.1.2' THEN 'CS2.1.1.2 Peuplement de conifères'
    WHEN cs_fin = 'CS2.1.1.3' THEN 'CS2.1.1.3 Peuplement mixte'
    WHEN cs_fin = 'CS2.1.2' THEN 'CS2.1.2 Formations arbustives et sous-arbrisseaux (Landes basses, formations arbustives organisées, …)'
    WHEN cs_fin = 'CS2.1.3' THEN 'CS2.1.3 Autres formations ligneuses (Vignes et autres lianes)'
    WHEN cs_fin = 'CS2.2.1' THEN 'CS2.2.1 Formations herbacées (Pelouses, prairies, terres arables, roselières, …)'
    WHEN cs_fin = 'CS2.2.2' THEN 'CS2.2.2 Autres formations non ligneuses (Lichen, mousse, bananiers, bambous, …)'
    ELSE 'Code inconnu'
END;


ALTER TABLE visufoncier.ocsge_diff 
ADD COLUMN us_debut_lib TEXT;
UPDATE visufoncier.ocsge_diff 
SET us_debut_lib = CASE 
    WHEN us_debut = 'US1.1' THEN 'US1.1 Agriculture'
    WHEN us_debut = 'US1.2' THEN 'US1.2 Sylviculture'
    WHEN us_debut = 'US1.3' THEN 'US1.3 Activités d''extraction' 
    WHEN us_debut = 'US1.4' THEN 'US1.4 Pêche et aquaculture'
    WHEN us_debut = 'US1.5' THEN 'US1.5 Autre'
	WHEN us_debut = 'US235' THEN 'US235 Production secondaire, tertiaire et usage résidentiel'
	WHEN us_debut = 'US2' THEN 'US2 Secondaire'
    WHEN us_debut = 'US3' THEN 'US3 Tertiaire'
    WHEN us_debut = 'US4.1.1' THEN 'US4.1.1 Routier'
    WHEN us_debut = 'US4.1.2' THEN 'US4.1.2 Ferré'
    WHEN us_debut = 'US4.1.3' THEN 'US4.1.3 Aérien'
    WHEN us_debut = 'US4.1.4' THEN 'US4.1.4 Eau'
    WHEN us_debut = 'US4.1.5' THEN 'US4.1.5 Autres réseaux de transport'
    WHEN us_debut = 'US4.2' THEN 'US4.2 Services de logistique et de stockage'
    WHEN us_debut = 'US4.3' THEN 'US4.3 Réseaux d''utilité publique'
    WHEN us_debut = 'US5' THEN 'US5 Résidentiel'
    WHEN us_debut = 'US6.1' THEN 'US6.1 Zones en transition'
    WHEN us_debut = 'US6.2' THEN 'US6.2 Zones abandonnées'
    WHEN us_debut = 'US6.3' THEN 'US6.3 Sans usage'
    WHEN us_debut = 'US6.6' THEN 'US6.6 Usage inconnu'
    ELSE 'Code inconnu'
END;


ALTER TABLE visufoncier.ocsge_diff 
ADD COLUMN us_fin_lib TEXT;
UPDATE visufoncier.ocsge_diff 
SET us_fin_lib = CASE 
    WHEN us_fin = 'US1.1' THEN 'US1.1 Agriculture'
    WHEN us_fin = 'US1.2' THEN 'US1.2 Sylviculture'
    WHEN us_fin = 'US1.3' THEN 'US1.3 Activités d''extraction' 
    WHEN us_fin = 'US1.4' THEN 'US1.4 Pêche et aquaculture'
    WHEN us_fin = 'US1.5' THEN 'US1.5 Autre'
	WHEN us_fin = 'US235' THEN 'US235 Production secondaire, tertiaire et usage résidentiel'
	WHEN us_fin = 'US2' THEN 'US2 Secondaire'
    WHEN us_fin = 'US3' THEN 'US3 Tertiaire'
    WHEN us_fin = 'US4.1.1' THEN 'US4.1.1 Routier'
    WHEN us_fin = 'US4.1.2' THEN 'US4.1.2 Ferré'
    WHEN us_fin = 'US4.1.3' THEN 'US4.1.3 Aérien'
    WHEN us_fin = 'US4.1.4' THEN 'US4.1.4 Eau'
    WHEN us_fin = 'US4.1.5' THEN 'US4.1.5 Autres réseaux de transport'
    WHEN us_fin = 'US4.2' THEN 'US4.2 Services de logistique et de stockage'
    WHEN us_fin = 'US4.3' THEN 'US4.3 Réseaux d''utilité publique' 
    WHEN us_fin = 'US5' THEN 'US5 Résidentiel'
    WHEN us_fin = 'US6.1' THEN 'US6.1 Zones en transition'
    WHEN us_fin = 'US6.2' THEN 'US6.2 Zones abandonnées'
    WHEN us_fin = 'US6.3' THEN 'US6.3 Sans usage'
    WHEN us_fin = 'US6.6' THEN 'US6.6 Usage inconnu'
    ELSE 'Code inconnu'
END;


--Appliquer les droits sur les tables si besoin 