-----------------------------------------------------------------
--Requete OCSGE (traitement sans application des seuils du décret)
-----------------------------------------------------------------

--z_ocsge_xx_annee_brut représente les données brutes téléchargées

--ATTENTION A REMPLACER DANS LA SYNTAXE '_xx' département et '_annee' année de début ou année de fin de l'analyse 
--Par exemple, si l'on veut traiter le département 35, remplacer _xx par _35. 
--Les millésimes du 35 étant 2017 pour le début d'analyse et 2020 pour la fin, lancer une fois les syntaxes avec _annee = _2017 et une fois avec _2020

 ------------------------------------------------------------------------------------------------------------
 --Objectif : creer des index, corriger les geométries, intersecter les données pour trouver un code insee. 
 -----------------------------------------------------------------------------------------------------------
 
 
 -- Comme il n'y a pas de code INSEE dans les données brutes de l'OCS GE NG, il faut aller le récupérer :
-- Créer une table qui intersecte l'OCSGE et admin express commune IGN pour récupérer le code INSEE, EPCI, DEP, région

CREATE TABLE visufoncier.ocsge_xx_annee_brut AS
WITH numbered_data AS (
    SELECT
        o.id AS id_origine,  -- Conserver l'ancien ID
        ROW_NUMBER() OVER () AS id,  -- Générer un nouvel ID unique
        o.code_cs,
        o.code_us,
        o.millesime,
        o.source,
        o.ossature,
        o.code_or,
        c.nom AS nom_commune,
        c.insee_com,
        c.siren_epci,
        c.insee_dep,
        c.insee_reg,
        ST_SetSRID(ST_Multi(COALESCE(ST_Intersection(o.geom, c.geom), o.geom)), 2154) AS geom
    FROM
        ocsge.z_ocsge_xx_annee_brut o
    LEFT JOIN
        ign.express_commune c 
    ON
        ST_Intersects(o.geom, c.geom)
    WHERE
        ST_IsValid(o.geom)
        AND (c.insee_com IS NULL OR c.insee_com LIKE 'xx%')  -- Filtrer les communes avec code INSEE xx ou sans commune
)
SELECT
    id_origine,
    id,
    code_cs,
    code_us,
    millesime,
    source,
    ossature,
    code_or,
    CASE WHEN insee_com IS NOT NULL THEN nom_commune ELSE NULL END AS nom_commune,
    CASE WHEN insee_com IS NOT NULL THEN insee_com ELSE NULL END AS insee_com,
    CASE WHEN insee_com IS NOT NULL THEN siren_epci ELSE NULL END AS siren_epci,
    CASE WHEN insee_com IS NOT NULL THEN insee_dep ELSE NULL END AS insee_dep,
    CASE WHEN insee_com IS NOT NULL THEN insee_reg ELSE NULL END AS insee_reg,
    geom
FROM
    numbered_data;

-- Partie géométrie

-- Création de l'index sur la géométrie pour la performance
CREATE INDEX ON visufoncier.ocsge_xx_annee_brut USING gist (geom);

-- Commentaire
COMMENT ON TABLE visufoncier.ocsge_xx_annee_brut IS 'Table qui intersecte les données de l''OCS GE NG (dans le schéma ocsge) brute pour le département xx, millésime annee, avec les données d''admin express et PCI vecteur pour retrouver les codes INSEE. Table utilisée pour toute l''analyse sur l''OCS GE.';

-- Vérifier si il y a des codes insee vides (il peut y en avoir quelques-uns, vérifier si <100)
SELECT count(*)
FROM visufoncier.ocsge_xx_annee_brut ob 
WHERE insee_com IS NULL;

-- Vérifier qu'il n'y a pas d'autre département que celui attendu dans la table
SELECT distinct insee_dep
FROM visufoncier.ocsge_xx_annee_brut ob;

-- Pour vérification : Sélectionner tous les types de géométries distincts dans la table 
-- Compter le nombre de géométries pour chaque type distinct
SELECT
    ST_GeometryType(geom) AS geometry_type,
    COUNT(*) AS count
FROM
    visufoncier.ocsge_xx_annee_brut
GROUP BY
    ST_GeometryType(geom);

-- Extraire les multipolygones des GEOMETRYCOLLECTION pour correction
UPDATE visufoncier.ocsge_xx_annee_brut
SET geom = ST_CollectionExtract(geom, 3)  -- Le 3 correspond aux Multipolygons
WHERE ST_GeometryType(geom) = 'ST_GeometryCollection';

-- Recompter le nombre de géométries pour chaque type distinct après correction
SELECT
    ST_GeometryType(geom) AS geometry_type,
    COUNT(*) AS count
FROM
    visufoncier.ocsge_xx_annee_brut
GROUP BY
    ST_GeometryType(geom);

-- Convertir les géométries en multipolygones si ce sont des polygones
UPDATE visufoncier.ocsge_xx_annee_brut
SET
    geom = CASE 
        WHEN ST_GeometryType(geom) = 'ST_Polygon' THEN ST_Multi(geom)
        ELSE geom
    END;

-- Supprimer les lignes dont les géométries ne sont pas des multipolygones (quelques lignes sont supprimées, moins de 10)
DELETE FROM visufoncier.ocsge_xx_annee_brut
WHERE ST_GeometryType(geom) <> 'ST_MultiPolygon';

-- Vérifier que tout est bien déclaré en multipolygon 2154. Il ne faut pas de 0 en SRID
SELECT Find_SRID('visufoncier', 'ocsge_xx_annee_brut', 'geom'), GeometryType(geom) 
FROM visufoncier.ocsge_xx_annee_brut
LIMIT 1;

ALTER TABLE visufoncier.ocsge_xx_annee_brut 
ALTER COLUMN geom TYPE geometry(MultiPolygon, 2154)
USING ST_SetSRID(geom, 2154);

-- Relancer le select pour voir si le format et le SRID ont été appliqués

-- Définir une clé primaire
ALTER TABLE visufoncier.ocsge_xx_annee_brut
ADD CONSTRAINT ocsge_xx_annee_brut_pkey PRIMARY KEY (id);

-- Récupérer des codes INSEE manquants à partir de PCI vecteur 
WITH cadastre_update AS (
    SELECT
        o.id,
        COALESCE(ST_Intersection(o.geom, cad.geom), o.geom) AS geom,  -- Intersection avec le cadastre ou géométrie originale si rien
        (cad.dep || cad.idu) AS insee_com,  -- Concaténation de 'dep' et 'idu' pour former 'insee_com'
        cad.tex2 AS nom_commune  -- Utilise nom_commune du cadastre directement
    FROM
        visufoncier.ocsge_xx_annee_brut o
    LEFT JOIN
        pci.cadastre_commune_2023 cad 
    ON
        ST_Intersects(o.geom, cad.geom)  -- Intersection avec le cadastre
    WHERE
        o.insee_com IS NULL  -- Ne traite que les lignes sans insee_com
        AND ST_IsValid(o.geom)  -- Filtre les géométries valides
        AND cad.dep = 'xx'  -- Filtre uniquement pour le département xx
)
UPDATE visufoncier.ocsge_xx_annee_brut o
SET
    geom = ST_Multi(cadastre_update.geom),  -- Forcer la géométrie à être multipolygone
    insee_com = cadastre_update.insee_com,  -- Mise à jour de insee_com depuis cadastre (concaténation de 'dep' et 'idu')
    nom_commune = cadastre_update.nom_commune  -- Mise à jour de nom_commune depuis cadastre
FROM
    cadastre_update
WHERE
    o.id = cadastre_update.id;

-- Rappatrier les bons noms de commune et le département, siren epci..
UPDATE visufoncier.ocsge_xx_annee_brut o
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



--correction complémentaires des géométries

update visufoncier.ocsge_xx_annee_brut set
geom=st_multi(st_simplify(ST_Multi(ST_CollectionExtract(ST_ForceCollection(
ST_MakeValid(geom)),3)),0)) WHERE st_geometrytype(geom) in ('ST_Polygon',
'ST_MultiPolygon') and st_isvalid(geom) is false;

--------------------------------------------------------------------------------------------------------------------
--Fin traitement des géométries, code insee...
--------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------
--Partie calcul des indicateurs : surface, millesime, catégorie cs, us...
--------------------------------------------------------------------------------------------------------------------

	
 -- Traitement CS US 
 --Calcul de surface
 
 --DANS LA TABLE LA PLUS RECENTE SUR LA PERIODE D'ANALYSE (par exemple, sur le 35, 2020)
ALTER TABLE visufoncier.ocsge_xx_annee_brut 
ADD COLUMN surface_m2 FLOAT8,
ADD COLUMN surface_ha FLOAT8;

UPDATE visufoncier.ocsge_xx_annee_brut
SET 
    surface_m2 = ST_Area(geom),
    surface_ha = ST_Area(geom) / 10000;
   
--Millesime de fin (à adapter) - exemple pour le 35, 2020
ALTER TABLE visufoncier.ocsge_xx_annee_brut 
ADD COLUMN millesime_fin TIMESTAMP;

UPDATE visufoncier.ocsge_xx_annee_brut 
SET millesime_fin = 'annee de fin-01-01 00:00:00';

--Millesime de début (à adapter) --exemple pour le 35, 2017
ALTER TABLE visufoncier.ocsge_xx_annee_brut 
ADD COLUMN millesime_fin TIMESTAMP;
UPDATE visufoncier.ocsge_xx_annee_brut 
SET millesime_debut = 'annee de debut-01-01 00:00:00';


-------------------------------------------------------------------------------------------------------------------------------------
-- Calcul des indicateurs catégories couverture du sol et usage : pour les prochaines vagues, vérifier les libellés de la nomenclature
-------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE visufoncier.ocsge_xx_annee_brut
ADD COLUMN code_cs_lib TEXT;

UPDATE visufoncier.ocsge_xx_annee_brut
SET code_cs_lib = CASE 
    WHEN code_cs = 'CS1.1.1.1' THEN 'CS1.1.1.1 Zones bâties'
    WHEN code_cs = 'CS1.1.1.2' THEN 'CS1.1.1.2 Zones non bâties (Routes, places, parking...)'
    WHEN code_cs = 'CS1.1.2.1' THEN 'CS1.1.2.1 Zones à matériaux minéraux'
    WHEN code_cs = 'CS1.1.2.2' THEN 'CS1.1.2.2 Zones à autres matériaux composites'
    WHEN code_cs = 'CS1.2.1' THEN 'CS1.2.1 Sols nus (Sable, pierres meubles, rochers saillants, …)'
    WHEN code_cs = 'CS1.2.2' THEN 'CS1.2.2 Surfaces d''eau (Eau continentale et maritime)'
    WHEN code_cs = 'CS1.2.3' THEN 'CS1.2.3 Névés et glaciers'
    WHEN code_cs = 'CS2.1.1.1' THEN 'CS2.1.1.1 Peuplement de feuillus'
    WHEN code_cs = 'CS2.1.1.2' THEN 'CS2.1.1.2 Peuplement de conifères'
    WHEN code_cs = 'CS2.1.1.3' THEN 'CS2.1.1.3 Peuplement mixte'
    WHEN code_cs = 'CS2.1.2' THEN 'CS2.1.2 Formations arbustives et sous-arbrisseaux (Landes basses, formations arbustives organisées, …)'
    WHEN code_cs = 'CS2.1.3' THEN 'CS2.1.3 Autres formations ligneuses (Vignes et autres lianes)'
    WHEN code_cs = 'CS2.2.1' THEN 'CS2.2.1 Formations herbacées (Pelouses, prairies, terres arables, roselières, …)'
    WHEN code_cs = 'CS2.2.2' THEN 'CS2.2.2 Autres formations non ligneuses (Lichen, mousse, bananiers, bambous, …)'
    ELSE 'Code inconnu'
END;

ALTER TABLE visufoncier.ocsge_xx_annee_brut
ADD COLUMN code_us_lib TEXT;

UPDATE visufoncier.ocsge_xx_annee_brut
SET code_us_lib = CASE 
    WHEN code_us = 'US1.1' THEN 'US1.1 Agriculture'
    WHEN code_us = 'US1.2' THEN 'US1.2 Sylviculture'
    WHEN code_us = 'US1.3' THEN 'US1.3 Activités d''extraction'
    WHEN code_us = 'US1.4' THEN 'US1.4 Pêche et aquaculture'
    WHEN code_us = 'US1.5' THEN 'US1.5 Autre'
    WHEN code_us = 'US235' THEN 'US235 Production secondaire, tertiaire et usage résidentiel'
    WHEN code_us = 'US2' THEN 'US2 Secondaire'
    WHEN code_us = 'US3' THEN 'US3 Tertiaire'
    WHEN code_us = 'US4.1.1' THEN 'US4.1.1 Routier'
    WHEN code_us = 'US4.1.2' THEN 'US4.1.2 Ferré'
    WHEN code_us = 'US4.1.3' THEN 'US4.1.3 Aérien'
    WHEN code_us = 'US4.1.4' THEN 'US4.1.4 Eau'
    WHEN code_us = 'US4.1.5' THEN 'US4.1.5 Autres réseaux de transport'
    WHEN code_us = 'US4.2' THEN 'US4.2 Services de logistique et de stockage'
    WHEN code_us = 'US4.3' THEN 'US4.3 Réseaux d''utilité publique'
    WHEN code_us = 'US5' THEN 'US5 Résidentiel'
    WHEN code_us = 'US6.1' THEN 'US6.1 Zones en transition'
    WHEN code_us = 'US6.2' THEN 'US6.2 Zones abandonnées'
    WHEN code_us = 'US6.3' THEN 'US6.3 Sans usage'
    WHEN code_us = 'US6.6' THEN 'US6.6 Usage inconnu'
    ELSE 'Code inconnu'
END;


---------------------------------------------------------------------------
--------------- Affectation d'une catégorie artificialisé/non artificialisé
---------------------------------------------------------------------------

-- Ajout de la colonne artif/non artif dans ocsge
ALTER TABLE visufoncier.ocsge_xx_annee_brut ADD COLUMN artif CHARACTER VARYING(10);

-- Marquer comme artificialisé en raison du bâti
UPDATE visufoncier.ocsge_xx_annee_brut
SET artif = 'artif'
WHERE code_cs = 'CS1.1.1.1';

-- Marquer comme artificialisé pour d'autres raisons
UPDATE visufoncier.ocsge_xx_annee_brut
SET artif = 'artif'
WHERE artif IS NULL
AND (
    code_cs = 'CS1.1.1.2'
    OR code_cs = 'CS1.1.2.2'
    OR (code_cs = 'CS1.1.2.1' AND code_us != 'US1.3')
    OR (code_cs LIKE 'CS2.2%' AND (
        code_us = 'US2'
        OR code_us = 'US3'
        OR code_us = 'US5'
        OR code_us = 'US235'
        OR code_us LIKE 'US4%'
        OR code_us = 'US6.1'
        OR code_us = 'US6.2'
    ))
);

-- Marquer comme non artificialisé
UPDATE visufoncier.ocsge_xx_annee_brut
SET artif = 'non artif'
WHERE artif IS NULL;


-- Index sur la colonne code_cs
CREATE INDEX idx_code_cs_xx_annee ON ocsge_xx_annee_brut(code_cs);

-- Index sur la colonne code_us
CREATE INDEX idx_code_us_xx_annee ON ocsge_xx_annee_brut(code_us);

-- Index sur la colonne code_cs_lib
CREATE INDEX idx_code_cs_lib_xx_annee ON ocsge_xx_annee_brut(code_cs_lib);

-- Index sur la colonne code_us_lib
CREATE INDEX idx_code_us_lib_xx_annee ON ocsge_xx_annee_brut(code_us_lib);

-- Index sur la colonne artif
CREATE INDEX idx_artif_xx_annee ON ocsge_xx_annee_brut(artif);


--------------------------------------------------------------
-- Création des variables de catégories couverture et usages avec les regroupements de la nomenclature
--------------------------------------------------------------

--Catégories couverture
-- Ajouter la colonne cs_regroup1
ALTER TABLE visufoncier.ocsge_xx_annee_brut
ADD COLUMN cs_regroup1 TEXT;

-- Mise à jour des valeurs de cs_regroup1
UPDATE visufoncier.ocsge_xx_annee_brut
SET cs_regroup1 = CASE 
    -- Catégories sans végétation (CS1)
    WHEN code_cs IN ('CS1.1.1.1', 'CS1.1.1.2') THEN 'CS1.1.1 Zones imperméables'
    WHEN code_cs IN ('CS1.1.2.1', 'CS1.1.2.2') THEN 'CS1.1.2 Zones perméables'
    WHEN code_cs IN ('CS1.2.1', 'CS1.2.2', 'CS1.2.3') THEN 'CS1.2 Surfaces naturelles'
    -- Catégories avec végétation (CS2)
    WHEN code_cs IN ('CS2.1.1.1', 'CS2.1.1.2', 'CS2.1.1.3') THEN 'CS2.1.1 Formations arborées'
    WHEN code_cs = 'CS2.1.2' THEN 'CS2.1.2 Formations arbustives et sous-arbrisseaux'
    WHEN code_cs = 'CS2.1.3' THEN 'CS2.1.3 Autres formations ligneuses'
    WHEN code_cs = 'CS2.2.1' THEN 'CS2.2.1 Formations herbacées'
    WHEN code_cs = 'CS2.2.2' THEN 'CS2.2.2 Autres formations non ligneuses'
    ELSE 'Inconnu'
END;

-- Ajouter la colonne cs_regroup2
ALTER TABLE visufoncier.ocsge_xx_annee_brut
ADD COLUMN cs_regroup2 TEXT;

-- Mise à jour des valeurs de cs_regroup2
UPDATE visufoncier.ocsge_xx_annee_brut
SET cs_regroup2 = CASE 
    -- Catégories sans végétation (CS1)
    WHEN code_cs IN ('CS1.1.1.1', 'CS1.1.1.2', 'CS1.1.2.1', 'CS1.1.2.2') THEN 'CS1.1 Surface anthropisées'
    -- Surface naturelles
    WHEN code_cs IN ('CS1.2.1', 'CS1.2.2', 'CS1.2.3') THEN 'CS1.2 Surfaces naturelles'
    -- Catégories avec végétation (CS2)
    WHEN code_cs IN ('CS2.1.1.1', 'CS2.1.1.2', 'CS2.1.1.3','CS2.1.2','CS2.1.3') THEN 'CS2.1 Végétation ligneuse'
    WHEN code_cs IN ('CS2.2.1','CS2.2.2') THEN 'CS2.2 Végétation non ligneuse'
    ELSE 'Inconnu'
END;

-- Ajouter la colonne cs_regroup3
ALTER TABLE visufoncier.ocsge_xx_annee_brut
ADD COLUMN cs_regroup3 TEXT;

-- Mise à jour des valeurs de cs_regroup3
UPDATE visufoncier.ocsge_xx_annee_brut
SET cs_regroup3 = CASE 
    -- Catégories sans végétation (CS1)
    WHEN code_cs IN ('CS1.1.1.1', 'CS1.1.1.2', 'CS1.1.2.1', 'CS1.1.2.2', 'CS1.2.1', 'CS1.2.2', 'CS1.2.3') THEN 'CS1 Sans végétation'
    -- Catégories avec végétation (CS2)
    WHEN code_cs IN ('CS2.1.1.1', 'CS2.1.1.2', 'CS2.1.1.3','CS2.1.2','CS2.1.3','CS2.2.1','CS2.2.2') THEN 'CS2 Avec végétation'
    ELSE 'Inconnu'
END;

--Catégories usage 

-- Ajouter la colonne us_regroup1
ALTER TABLE visufoncier.ocsge_xx_annee_brut 
ADD COLUMN us_regroup1 TEXT;

-- Mise à jour des valeurs de us_regroup1
UPDATE visufoncier.ocsge_xx_annee_brut 
SET us_regroup1 = CASE 
    -- Production primaire (US1)
    WHEN code_us LIKE 'US1%' THEN 'US1 Production primaire'

    -- Production secondaire, tertiaire et usage résidentiel (US235)
    WHEN code_us IN ('US2', 'US3', 'US5', 'US235') THEN 'US235 Production secondaire, tertiaire et usage résidentiel'

    -- Réseaux de transport et utilité publique (US4)
    WHEN code_us LIKE 'US4%' THEN 'US4 Réseaux de transport logistiques et infrastructures'

    -- Autres usages (US6)
    WHEN code_us LIKE 'US6%' THEN 'US6 Autres usages'

    ELSE 'Inconnu'
END;
