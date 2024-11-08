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
-- Création du schéma IGN (si nécessaire)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS ign;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remarques :
-- Si les tables existent déjà dans le schéma 'geobretagne', vérifier la date de mise à jour pour s'assurer qu'elles sont à jour.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Chargement des données de la table des communes (à adapter si besoin)

-- Chargement des données de la table des EPCI (ajouter la syntaxe appropriée)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Traitement des colonnes de la table des EPCI
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Si les données sont nouvellement chargées, renommer certaines colonnes pour correspondre aux standards utilisés dans le projet.

-- Renommer la colonne 'code_siren' en 'code_epci' :
ALTER TABLE ign.express_epci
RENAME COLUMN code_siren TO code_epci;

-- Renommer la colonne 'nom' en 'nom_epci' :
ALTER TABLE ign.express_epci
RENAME COLUMN nom TO nom_epci;

-- Renommer la colonne 'nature' en 'type_epci' :
ALTER TABLE ign.express_epci
RENAME COLUMN nature TO type_epci;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Jointure et traitement des données Admin Express
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Objectif : enrichir la table 'mos_foncier_agrege_2011_2021' avec des informations géographiques à partir des tables 'express_commune' et 'express_epci'


-- Étape 1 : Ajout de colonnes supplémentaires dans la table 'visufoncier.mos_foncier_agrege_2011_2021'
ALTER TABLE visufoncier.mos_foncier_agrege_2011_2021
ADD COLUMN insee_com VARCHAR,
ADD COLUMN nom_commune VARCHAR,
ADD COLUMN siren_epci VARCHAR,
ADD COLUMN insee_dep VARCHAR,
ADD COLUMN insee_reg VARCHAR;

-- Étape 2 : Mise à jour des colonnes en joignant la table 'ign.express_commune' via le code INSEE
UPDATE visufoncier.mos_foncier_agrege_2011_2021
SET 
    insee_com = ign.express_commune.insee_com,
    nom_commune = ign.express_commune.nom,
    siren_epci = ign.express_commune.siren_epci,
    insee_dep = ign.express_commune.insee_dep,
    insee_reg = ign.express_commune.insee_reg
FROM 
    ign.express_commune
WHERE 
    visufoncier.mos_foncier_agrege_2011_2021.codegeo_mos = ign.express_commune.insee_com;

-- Étape 3 : Jointure avec la table 'express_epci' pour enrichir la table avec le nom de l'EPCI
ALTER TABLE visufoncier.mos_foncier_agrege_2011_2021
ADD COLUMN nom_epci VARCHAR;

UPDATE visufoncier.mos_foncier_agrege_2011_2021
SET nom_epci = ign.express_epci.nom_epci
FROM ign.express_epci
WHERE visufoncier.mos_foncier_agrege_2011_2021.siren_epci = ign.express_epci.code_epci;

-- Étape 4 : Création d'index pour optimiser les requêtes sur la table 'mos_foncier_agrege_2011_2021'
CREATE INDEX IF NOT EXISTS idx_nom_commune
ON visufoncier.mos_foncier_agrege_2011_2021 (nom_commune);

CREATE INDEX IF NOT EXISTS idx_nom_epci
ON visufoncier.mos_foncier_agrege_2011_2021 (nom_epci);

CREATE INDEX IF NOT EXISTS idx_nom_scot
ON visufoncier.mos_foncier_agrege_2011_2021 (nom_scot);

CREATE INDEX IF NOT EXISTS idx_insee_com
ON visufoncier.mos_foncier_agrege_2011_2021 (insee_com);

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Jointure et traitement des données SCOT
-------------------------------------------

-- Jointure et traitement des données SCOT

-- Objectif : Enrichir la table 'mos_foncier_agrege_2011_2021' avec les informations SCOT

-- Étape 1 : Ajouter une colonne 'nom_scot'
ALTER TABLE visufoncier.mos_foncier_agrege_2011_2021
ADD COLUMN nom_scot VARCHAR(255);

-- Étape 2 : Mettre à jour la colonne 'nom_scot' via une jointure avec 'ff_obs_artif_conso_com'
UPDATE visufoncier.mos_foncier_agrege_2011_2021 v
SET nom_scot = s.scot
FROM visufoncier.ff_obs_artif_conso_com s
WHERE v.insee_com = s.idcom;

-- Étape 3 : Normalisation des noms de SCOT
UPDATE visufoncier.mos_foncier_agrege_2011_2021
SET nom_scot = CASE
    WHEN nom_scot = 'SCoT Roi Morvan Communauté - Centre Ouest Bretagne' THEN 'SCOT DU CENTRE OUEST BRETAGNE'
    WHEN nom_scot = 'SCoT de Dinan Agglomération' THEN 'SCOT-AEC DU PAYS DE DINAN'
    WHEN nom_scot = 'SCoT du Pays de Guingamp' THEN 'SCOT DU PAYS DE GUINGAMP'
    WHEN nom_scot = 'SCoT du Trégor' THEN 'SCOT DU TREGOR'
    WHEN nom_scot = 'SCoT des Communautés du Pays de Saint-Malo' THEN 'SCOT DES COMMUNAUTES DU PAYS DE SAINT MALO'
    WHEN nom_scot = 'SCoT Loudeac Communauté Bretagne Centre' THEN 'SCOT LOUDEAC COMMUNAUTE BRETAGNE CENTRE'
    WHEN nom_scot = 'SCoT du Pays de Pontivy' THEN 'SCOT DU PAYS DE PONTIVY'
    WHEN nom_scot = 'SCoT du Pays de Saint-Brieuc' THEN 'SCOT DU PAYS DE SAINT BRIEUC'
    ELSE nom_scot
END;

-- Étape 4 : Modification des données en cas de fusion de communes depuis 2023
UPDATE visufoncier.mos_foncier_agrege_2011_2021
SET insee_com = '35062',
    nom_commune = 'La Chapelle-Fleurigné',
    siren_epci = '200072452',
    insee_dep = '35',
    insee_reg = '53',
    nom_epci = 'CA Fougères Agglomération',
    nom_scot = 'SCOT DU PAYS DE FOUGERES'
WHERE nom_commune_mos = 'Fleurigné';

-- À compléter : modifications et fusions d'EPCI et de SCOT depuis 2023


--Modification / Fusion d'EPCI depuis 2023



--Modification / Fusion SCOT depuis 2023


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Historique des fusions de communes
-------------------------------------

-- Objectif : Télécharger et traiter les données des fusions de communes pour garantir la précision des informations géographiques dans les tables.

-- Dans un environnement virtuel (Envfoncier), exécuter le fichier python "syntaxe_insee_fusioncom".
-- Cette syntaxe python va lancer le téléchargement du fichier et permet d'avoir une donnée propre en sortie (supprime les lignes hors Bretagne, garde les bonnes colonnes...)
-- Attention, le script python est calibré pour filtrer sur la Bretagne. Ligne à modifier si besoin : df_filtered = df[df['com_ini'].astype(str).str.startswith(('22', '29', '56', '35'))]
-- Cette table sert à gérer les fusions de communes dans les tables. 

-- La syntaxe python comprend l'importation sur POSTGRESQL, schéma visufoncier. 
-- Il faudra changer les identifiants de connexion dans le fichier .env dans l'environnement Envfoncier

-- Vérifier l'importation et commenter la table
COMMENT ON TABLE visufoncier.insee_fusioncom IS 
'Historique des fusions de communes INSEE'; 


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Téléchargement des fichiers fonciers du portail de l'artificialisation 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

-- Objectif : Télécharger et préparer les données d'artificialisation des espaces naturels, agricoles et forestiers pour l'analyse.
-- Télécharger en CSV sur le portail de l'artificialisation : https://www.data.gouv.fr/fr/datasets/consommation-despaces-naturels-agricoles-et-forestiers-du-1er-janvier-2009-au-1er-janvier-2023/
-- Fichiers à télécharger : 
-- - obs-artif-conso-com-2009-2023.zip 
-- - description-indicateurs-2009-2023.pdf (pour info sur les variables)

-- Pour les prochaines vagues, adapter la syntaxe avec les nouvelles années.

-- Importer sur le schéma visufoncier "ff_obs_artif_conso_com".
--Creer la table
CREATE TABLE visufoncier.ff_obs_artif_conso_com (
	idcom varchar NULL,
	idcomtxt varchar(255) NULL,
	idreg int4 NULL,
	idregtxt varchar(255) NULL,
	iddep int4 NULL,
	iddeptxt varchar(255) NULL,
	epci23 varchar(255) NULL,
	epci23txt varchar(255) NULL,
	scot varchar(255) NULL,
	aav2020 varchar(255) NULL,
	aav2020txt int4 NULL,
	aav2020_typo varchar(255) NULL,
	naf09art10 int4 NULL,
	art09act10 int4 NULL,
	art09hab10 int4 NULL,
	art09mix10 int4 NULL,
	art09rou10 int4 NULL,
	art09fer10 int4 NULL,
	art09inc10 int4 NULL,
	naf10art11 int4 NULL,
	art10act11 int4 NULL,
	art10hab11 int4 NULL,
	art10mix11 int4 NULL,
	art10rou11 int4 NULL,
	art10fer11 int4 NULL,
	art10inc11 int4 NULL,
	naf11art12 int4 NULL,
	art11act12 int4 NULL,
	art11hab12 int4 NULL,
	art11mix12 int4 NULL,
	art11rou12 int4 NULL,
	art11fer12 int4 NULL,
	art11inc12 int4 NULL,
	naf12art13 int4 NULL,
	art12act13 int4 NULL,
	art12hab13 int4 NULL,
	art12mix13 int4 NULL,
	art12rou13 int4 NULL,
	art12fer13 int4 NULL,
	art12inc13 int4 NULL,
	naf13art14 int4 NULL,
	art13act14 int4 NULL,
	art13hab14 int4 NULL,
	art13mix14 int4 NULL,
	art13rou14 int4 NULL,
	art13fer14 int4 NULL,
	art13inc14 int4 NULL,
	naf14art15 int4 NULL,
	art14act15 int4 NULL,
	art14hab15 int4 NULL,
	art14mix15 int4 NULL,
	art14rou15 int4 NULL,
	art14fer15 int4 NULL,
	art14inc15 int4 NULL,
	naf15art16 int4 NULL,
	art15act16 int4 NULL,
	art15hab16 int4 NULL,
	art15mix16 int4 NULL,
	art15rou16 int4 NULL,
	art15fer16 int4 NULL,
	art15inc16 int4 NULL,
	naf16art17 int4 NULL,
	art16act17 int4 NULL,
	art16hab17 int4 NULL,
	art16mix17 int4 NULL,
	art16rou17 int4 NULL,
	art16fer17 int4 NULL,
	art16inc17 int4 NULL,
	naf17art18 int4 NULL,
	art17act18 int4 NULL,
	art17hab18 int4 NULL,
	art17mix18 int4 NULL,
	art17rou18 int4 NULL,
	art17fer18 int4 NULL,
	art17inc18 int4 NULL,
	naf18art19 int4 NULL,
	art18act19 int4 NULL,
	art18hab19 int4 NULL,
	art18mix19 int4 NULL,
	art18rou19 int4 NULL,
	art18fer19 int4 NULL,
	art18inc19 int4 NULL,
	naf19art20 int4 NULL,
	art19act20 int4 NULL,
	art19hab20 int4 NULL,
	art19mix20 int4 NULL,
	art19rou20 int4 NULL,
	art19fer20 int4 NULL,
	art19inc20 int4 NULL,
	naf20art21 int4 NULL,
	art20act21 int4 NULL,
	art20hab21 int4 NULL,
	art20mix21 int4 NULL,
	art20rou21 int4 NULL,
	art20fer21 int4 NULL,
	art20inc21 int4 NULL,
	naf21art22 int4 NULL,
	art21act22 int4 NULL,
	art21hab22 int4 NULL,
	art21mix22 int4 NULL,
	art21rou22 int4 NULL,
	art21fer22 int4 NULL,
	art21inc22 int4 NULL,
	naf22art23 int4 NULL,
	art22act23 int4 NULL,
	art22hab23 int4 NULL,
	art22mix23 int4 NULL,
	art22rou23 int4 NULL,
	art22fer23 int4 NULL,
	art22inc23 int4 NULL,
	naf09art23 int4 NULL,
	art09act23 int4 NULL,
	art09hab23 int4 NULL,
	art09mix23 int4 NULL,
	art09inc23 int4 NULL,
	art09rou23 int4 NULL,
	art09fer23 int4 NULL,
	artcom0923 float4 NULL,
	pop14 int4 NULL,
	pop20 int4 NULL,
	pop1420 int4 NULL,
	men14 int4 NULL,
	men20 int4 NULL,
	men1420 int4 NULL,
	emp14 int4 NULL,
	emp20 int4 NULL,
	emp1420 int4 NULL,
	mepart1420 float4 NULL,
	menhab1420 float4 NULL,
	artpop1420 float4 NULL,
	surfcom2023 int4 NULL,
	naf11art21 numeric NULL,
	updated int4 NULL
);

--Importer les données à partir du CSV
COPY visufoncier.ff_obs_artif_conso_com (
    idcom,
    idcomtxt,
    idreg,
    idregtxt,
    iddep,
    iddeptxt,
    epci23,
    epci23txt,
    scot,
    aav2020,
    aav2020txt,
    aav2020_typo,
    naf09art10,
    art09act10,
    art09hab10,
    art09mix10,
    art09rou10,
    art09fer10,
    art09inc10,
    naf10art11,
    art10act11,
    art10hab11,
    art10mix11,
    art10rou11,
    art10fer11,
    art10inc11,
    naf11art12,
    art11act12,
    art11hab12,
    art11mix12,
    art11rou12,
    art11fer12,
    art11inc12,
    naf12art13,
    art12act13,
    art12hab13,
    art12mix13,
    art12rou13,
    art12fer13,
    art12inc13,
    naf13art14,
    art13act14,
    art13hab14,
    art13mix14,
    art13rou14,
    art13fer14,
    art13inc14,
    naf14art15,
    art14act15,
    art14hab15,
    art14mix15,
    art14rou15,
    art14fer15,
    art14inc15,
    naf15art16,
    art15act16,
    art15hab16,
    art15mix16,
    art15rou16,
    art15fer16,
    art15inc16,
    naf16art17,
    art16act17,
    art16hab17,
    art16mix17,
    art16rou17,
    art16fer17,
    art16inc17,
    naf17art18,
    art17act18,
    art17hab18,
    art17mix18,
    art17rou18,
    art17fer18,
    art17inc18,
    naf18art19,
    art18act19,
    art18hab19,
    art18mix19,
    art18rou19,
    art18fer19,
    art18inc19,
    naf19art20,
    art19act20,
    art19hab20,
    art19mix20,
    art19rou20,
    art19fer20,
    art19inc20,
    naf20art21,
    art20act21,
    art20hab21,
    art20mix21,
    art20rou21,
    art20fer21,
    art20inc21,
    naf21art22,
    art21act22,
    art21hab22,
    art21mix22,
    art21rou22,
    art21fer22,
    art21inc22,
    naf22art23,
    art22act23,
    art22hab23,
    art22mix23,
    art22rou23,
    art22fer23,
    art22inc23,
    naf09art23,
    art09act23,
    art09hab23,
    art09mix23,
    art09inc23,
    art09rou23,
    art09fer23,
    artcom0923,
    pop14,
    pop20,
    pop1420,
    men14,
    men20,
    men1420,
    emp14,
    emp20,
    emp1420,
    mepart1420,
    menhab1420,
    artpop1420,
    surfcom2023,
    naf11art21,
    updated
)
FROM '/path/to/your/file.csv'
DELIMITER ','
CSV HEADER;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- Calcul des consommations d'artificialisation
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

-- Objectif : Ajouter une colonne pour calculer la consommation d'espace entre 2011 et 2021 (jusqu'au 1er janvier 2021) dans la table des observations d'artificialisation.
ALTER TABLE visufoncier.ff_obs_artif_conso_com
ADD COLUMN naf11art21 numeric;

UPDATE visufoncier.ff_obs_artif_conso_com
SET naf11art21 = naf11art12 + naf12art13 + naf13art14 + naf14art15 + naf15art16 + naf16art17 + naf17art18 + naf18art19 + naf19art20 + naf20art21;

/* -- Ajouter une colonne pour calculer la consommation entre 2021 et 2024 (exemple)
ALTER TABLE visufoncier.ff_obs_artif_conso_com
ADD COLUMN naf21art24 numeric;

UPDATE visufoncier.ff_obs_artif_conso_com
SET naf21art24 = naf21art22 + naf22art23 + naf23art24; */


-- Objectif : Vérifier et mettre à jour les identifiants de communes suite aux fusions dans la table des observations d'artificialisation.
ALTER TABLE visufoncier.ff_obs_artif_conso_com DROP COLUMN updated;
ALTER TABLE visufoncier.ff_obs_artif_conso_com
ADD COLUMN updated integer;

UPDATE visufoncier.ff_obs_artif_conso_com AS vp
SET 
    updated = 1
WHERE EXISTS (
    SELECT 1 FROM visufoncier.insee_fusioncom AS vf 
    WHERE (vf.com_ini = vp.idcom AND vf.com_ini <> vf.com_fin) OR (vf.com_fin = vp.idcom AND vf.lib_com_fin <> vp.idcomtxt)
);

-- Si des fusions existent : 

UPDATE visufoncier.ff_obs_artif_conso_com AS vp
SET 
    idcom = vf.com_fin
FROM visufoncier.insee_fusioncom AS vf
WHERE vp.updated = 1
AND vp.idcom = vf.com_ini;

UPDATE visufoncier.ff_obs_artif_conso_com AS vp
SET 
    idcomtxt = vf.lib_com_fin
FROM visufoncier.insee_fusioncom AS vf
WHERE vp.updated = 1
AND vp.idcom = vf.com_fin;


--Additionner les lignes 
CREATE TABLE visufoncier.ff_obs_artif_conso_com_aggregated AS
SELECT 
    idcom,
    MAX(idcomtxt) AS idcomtxt, 
    MAX(idreg) AS idreg, 
    MAX(idregtxt) AS idregtxt, 
    MAX(iddep) AS iddep, 
    MAX(iddeptxt) AS iddeptxt, 
    MAX(epci23) AS epci23, 
    MAX(epci23txt) AS epci23txt, 
    MAX(scot) AS scot, 
    MAX(aav2020) AS aav2020, 
    MAX(aav2020txt) AS aav2020txt, 
    MAX(aav2020_typo) AS aav2020_typo, 
    SUM(naf09art10) AS naf09art10,
    SUM(art09act10) AS art09act10,
    SUM(art09hab10) AS art09hab10,
    SUM(art09mix10) AS art09mix10,
    SUM(art09rou10) AS art09rou10,
    SUM(art09fer10) AS art09fer10,
    SUM(art09inc10) AS art09inc10,
    SUM(naf10art11) AS naf10art11,
    SUM(art10act11) AS art10act11,
    SUM(art10hab11) AS art10hab11,
    SUM(art10mix11) AS art10mix11,
    SUM(art10rou11) AS art10rou11,
    SUM(art10fer11) AS art10fer11,
    SUM(art10inc11) AS art10inc11,
    SUM(naf11art12) AS naf11art12,
    SUM(art11act12) AS art11act12,
    SUM(art11hab12) AS art11hab12,
    SUM(art11mix12) AS art11mix12,
    SUM(art11rou12) AS art11rou12,
    SUM(art11fer12) AS art11fer12,
    SUM(art11inc12) AS art11inc12,
    SUM(naf12art13) AS naf12art13,
    SUM(art12act13) AS art12act13,
    SUM(art12hab13) AS art12hab13,
    SUM(art12mix13) AS art12mix13,
    SUM(art12rou13) AS art12rou13,
    SUM(art12fer13) AS art12fer13,
    SUM(art12inc13) AS art12inc13,
    SUM(naf13art14) AS naf13art14,
    SUM(art13act14) AS art13act14,
    SUM(art13hab14) AS art13hab14,
    SUM(art13mix14) AS art13mix14,
    SUM(art13rou14) AS art13rou14,
    SUM(art13fer14) AS art13fer14,
    SUM(art13inc14) AS art13inc14,
    SUM(naf14art15) AS naf14art15,
    SUM(art14act15) AS art14act15,
    SUM(art14hab15) AS art14hab15,
    SUM(art14mix15) AS art14mix15,
    SUM(art14rou15) AS art14rou15,
    SUM(art14fer15) AS art14fer15,
    SUM(art14inc15) AS art14inc15,
    SUM(naf15art16) AS naf15art16,
    SUM(art15act16) AS art15act16,
    SUM(art15hab16) AS art15hab16,
    SUM(art15mix16) AS art15mix16,
    SUM(art15rou16) AS art15rou16,
    SUM(art15fer16) AS art15fer16,
    SUM(art15inc16) AS art15inc16,
    SUM(naf16art17) AS naf16art17,
    SUM(art16act17) AS art16act17,
    SUM(art16hab17) AS art16hab17,
    SUM(art16mix17) AS art16mix17,
    SUM(art16rou17) AS art16rou17,
    SUM(art16fer17) AS art16fer17,
    SUM(art16inc17) AS art16inc17,
    SUM(naf17art18) AS naf17art18,
    SUM(art17act18) AS art17act18,
    SUM(art17hab18) AS art17hab18,
    SUM(art17mix18) AS art17mix18,
    SUM(art17rou18) AS art17rou18,
    SUM(art17fer18) AS art17fer18,
    SUM(art17inc18) AS art17inc18,
    SUM(naf18art19) AS naf18art19,
    SUM(art18act19) AS art18act19,
    SUM(art18hab19) AS art18hab19,
    SUM(art18mix19) AS art18mix19,
    SUM(art18rou19) AS art18rou19,
    SUM(art18fer19) AS art18fer19,
    SUM(art18inc19) AS art18inc19,
    SUM(naf19art20) AS naf19art20,
    SUM(art19act20) AS art19act20,
    SUM(art19hab20) AS art19hab20,
    SUM(art19mix20) AS art19mix20,
    SUM(art19rou20) AS art19rou20,
    SUM(art19fer20) AS art19fer20,
    SUM(art19inc20) AS art19inc20,
    SUM(naf20art21) AS naf20art21,
    SUM(art20act21) AS art20act21,
    SUM(art20hab21) AS art20hab21,
    SUM(art20mix21) AS art20mix21,
    SUM(art20rou21) AS art20rou21,
    SUM(art20fer21) AS art20fer21,
    SUM(art20inc21) AS art20inc21,
    SUM(naf21art22) AS naf21art22,
    SUM(art21act22) AS art21act22,
    SUM(art21hab22) AS art21hab22,
    SUM(art21mix22) AS art21mix22,
    SUM(art21rou22) AS art21rou22,
    SUM(art21fer22) AS art21fer22,
    SUM(art21inc22) AS art21inc22,
    SUM(naf22art23) AS naf22art23,
    SUM(art22act23) AS art22act23,
    SUM(art22hab23) AS art22hab23,
    SUM(art22mix23) AS art22mix23,
    SUM(art22rou23) AS art22rou23,
    SUM(art22fer23) AS art22fer23,
    SUM(art22inc23) AS art22inc23,
    SUM(naf09art23) AS naf09art23,
    SUM(art09act23) AS art09act23,
    SUM(art09hab23) AS art09hab23,
    SUM(art09mix23) AS art09mix23,
    SUM(art09inc23) AS art09inc23,
    SUM(art09rou23) AS art09rou23,
    SUM(art09fer23) AS art09fer23,
    SUM(pop14) AS pop14,
    SUM(pop20) AS pop20,
    SUM(pop1420) AS pop1420,
    SUM(men14) AS men14,
    SUM(men20) AS men20,
    SUM(men1420) AS men1420,
    SUM(emp14) AS emp14,
    SUM(emp20) AS emp20,
    SUM(emp1420) AS emp1420,
    SUM(mepart1420) AS mepart1420,
    SUM(menhab1420) AS menhab1420,
    SUM(artpop1420) AS artpop1420,
    SUM(surfcom2023) AS surfcom2023,
    SUM(naf11art21) AS naf11art21
FROM 
    visufoncier.ff_obs_artif_conso_com
GROUP BY 
    idcom;

   
-- Identifier les lignes où les valeurs de naf11art21 diffèrent entre la table des observations d'artificialisation et la table agrégée.
SELECT 
    visufoncier.ff_obs_artif_conso_com.idcom,
    visufoncier.ff_obs_artif_conso_com.naf11art21 AS naf11art21_base,
    visufoncier.ff_obs_artif_conso_com_aggregated.naf11art21 AS naf11art21_aggregated
FROM 
    visufoncier.ff_obs_artif_conso_com
JOIN 
    visufoncier.ff_obs_artif_conso_com_aggregated
ON 
    visufoncier.ff_obs_artif_conso_com.idcom = visufoncier.ff_obs_artif_conso_com_aggregated.idcom
WHERE 
    visufoncier.ff_obs_artif_conso_com.naf11art21 IS DISTINCT FROM visufoncier.ff_obs_artif_conso_com_aggregated.naf11art21;


-- Supprimer l'ancienne table des observations d'artificialisation et renommer la table agrégée pour qu'elle remplace l'ancienne.
DROP TABLE IF EXISTS visufoncier.ff_obs_artif_conso_com;
ALTER TABLE visufoncier.ff_obs_artif_conso_com_aggregated
RENAME TO ff_obs_artif_conso_com;

COMMENT ON TABLE visufoncier.ff_obs_artif_conso_com IS
'Table des fichiers fonciers : pour calculer le flux de consommation selon les FF';


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INSEE : Historique de la population municipale par commune
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Objectif : Exécuter le fichier Python "syntaxe_insee_popmun.py" dans un environnement virtuel (Envfoncier).
-- Ce script va lancer le téléchargement des données de population et générer un fichier propre en sortie. 
-- Remarque : Le script est calibré pour filtrer sur la Bretagne. Modifier la ligne suivante si nécessaire : df_filtered = df[df['reg'] == 53]
-- Source des données : https://www.insee.fr/fr/statistiques/3698339

-- Objectif : Vérifier l'importation des données dans PostgreSQL.
-- La syntaxe Python doit importer les données dans la base de données PostgreSQL.

-- Pour vérifier l'importation des données, exécuter la requête suivante :
SELECT * FROM visufoncier.insee_popmun;

--Supprimer les années précédentes si pas utile dans l'analyse
ALTER TABLE visufoncier.insee_popmun
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
COMMENT ON TABLE visufoncier.insee_insee_popmun IS
'Population municipale selon l''INSEE historique 1876-2021 par commune';

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INSEE : Chiffres de l'emploi année 2020 par commune (xlsx)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Objectif : Exécuter le fichier Python "syntaxe_insee_emploi_2020.py" dans un environnement virtuel (Envfoncier).
-- Ce script va lancer le téléchargement et générer un fichier propre en sortie.
-- Remarque : Le script est calibré pour filtrer sur la Bretagne. Modifier la ligne suivante si nécessaire : df_filtered_2020 = df_2020[df_2020['reg'] == 53]
-- Source des données : https://www.insee.fr/fr/statistiques/7632867?sommaire=7632977&q=Emploi+-%20population+active+en+2020

-- Le fichier CSV sera sauvegardé dans le dossier Téléchargements.
-- L'importation dans PostgreSQL est gérée via la syntaxe Python.

COMMENT ON TABLE visufoncier.insee_emploi_2020 IS
'Chiffres de l''emploi selon l''INSEE année 2020 par commune';

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INSEE : Chiffres de l'emploi année 2011 par commune (xls)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Source des données : https://www.insee.fr/fr/statistiques/2044817#consulter
-- Objectif : Exécuter le fichier Python "syntaxe_insee_emploi_2011.py" dans un environnement virtuel (Envfoncier).
-- Ce script va lancer le téléchargement et générer un fichier propre en sortie.
-- Remarque : Le script est calibré pour filtrer sur la Bretagne. Modifier la ligne suivante si nécessaire : df_filtered_2011 = df_2011[df_2011['reg'] == 53]
-- Attention : Lancer le script dans un environnement virtuel à cause du format XLS du fichier.

-- Le fichier CSV sera sauvegardé dans le dossier Téléchargements.
-- L'importation dans PostgreSQL est gérée via la syntaxe Python.

COMMENT ON TABLE visufoncier.insee_emploi_2011 IS
'Chiffres de l''emploi selon l''INSEE année 2011 par commune';

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INSEE : Chiffres de l'emploi année 2017 par commune (xlsx)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Objectif : Exécuter le fichier Python "syntaxe_insee_emploi_2017.py" dans un environnement virtuel (Envfoncier).
-- Ce script va lancer le téléchargement et générer un fichier propre en sortie.
-- Remarque : Le script est calibré pour filtrer sur la Bretagne. Modifier la ligne suivante si nécessaire : df_filtered_2017 = df_2017[df_2017['reg'] == 53]

-- Le fichier CSV sera sauvegardé dans le dossier Téléchargements.
-- L'importation dans PostgreSQL est gérée via la syntaxe Python.

COMMENT ON TABLE visufoncier.insee_emploi_2017 IS
'Chiffres de l''emploi selon l''INSEE année 2017 par commune';

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INSEE : Chiffres de l'emploi année 2018 par commune (xlsx)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Objectif : Exécuter le fichier Python "syntaxe_insee_emploi_2018.py" dans un environnement virtuel (Envfoncier).
-- Ce script va lancer le téléchargement et générer un fichier propre en sortie.
-- Remarque : Le script est calibré pour filtrer sur la Bretagne. Modifier la ligne suivante si nécessaire : df_filtered_2018 = df_2018[df_2018['reg'] == 53]

-- Le fichier CSV sera sauvegardé dans le dossier Téléchargements.
-- L'importation dans PostgreSQL est gérée via la syntaxe Python.

COMMENT ON TABLE visufoncier.insee_emploi_2018 IS
'Chiffres de l''emploi selon l''INSEE année 2018 par commune';


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--INSEE : Nombre de ménage en 2020 par commune
----------------------------------------------
--https://www.insee.fr/fr/statistiques/7633206?sommaire=7633255
--Dans un environnement virtuel (Envfoncier), exécuter le fichier python "syntaxe_insee_menage_2020.py"
--Cette syntaxe python va lancer le téléchargement et permet d'avoir un fichier propre en sortie. Attention, le script python est calibré pour filtrer sur la Bretagne. Ligne à modifier: df_filtered_2020 = df_2020[df_2020['reg'] == 53]

--L'import sous POSTGRESQL est géré via la syntaxe python


COMMENT ON TABLE visufoncier.insee_menage_2020 IS
'Nombre de ménage par commune selon l''INSEE historique 2020 par commune';


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--INSEE : Nombre de ménage en 2011 par commune
----------------------------------------------
--https://www.insee.fr/fr/statistiques/zones/2132555?debut=0&q=Couples-Familles-M%C3%A9nages+en+2011
--Dans un environnement virtuel (Envfoncier), exécuter le fichier python "syntaxe_insee_menage_2011.py"
--Cette syntaxe python va lancer le téléchargement et permet d'avoir un fichier propre en sortie. Attention, le script python est calibré pour filtrer sur la Bretagne. Ligne à modifier: df_filtered_2011 = df_2011[df_2011['reg'] == 53]

--L'import sous POSTGRESQL est géré via la syntaxe python
 

COMMENT ON TABLE visufoncier.insee_menage_2011 IS
'Nombre de ménage par commune selon l''INSEE historique 2011 par commune';

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--INSEE : Nombre de ménage en 2017 par commune
----------------------------------------------

--Dans un environnement virtuel (Envfoncier), exécuter le fichier python "syntaxe_insee_menage_2017.py"
--Cette syntaxe python va lancer le téléchargement et permet d'avoir un fichier propre en sortie. Attention, le script python est calibré pour filtrer sur la Bretagne. Ligne à modifier: df_filtered_2011 = df_2011[df_2011['reg'] == 53]

--L'import sous POSTGRESQL est géré via la syntaxe python
 

COMMENT ON TABLE visufoncier.insee_menage_2017 IS
'Nombre de ménage par commune selon l''INSEE historique 2017 par commune';

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--INSEE : Nombre de ménage en 2018 par commune
----------------------------------------------

--Dans un environnement virtuel (Envfoncier), exécuter le fichier python "syntaxe_insee_menage_2018.py"
--Cette syntaxe python va lancer le téléchargement et permet d'avoir un fichier propre en sortie. Attention, le script python est calibré pour filtrer sur la Bretagne. Ligne à modifier: df_filtered_2011 = df_2011[df_2011['reg'] == 53]

--L'import sous POSTGRESQL est géré via la syntaxe python
 

COMMENT ON TABLE visufoncier.insee_menage_2018 IS
'Nombre de ménage par commune selon l''INSEE historique 2018 par commune';

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Traitement des communes fusionnées 
-------------------------------------

-- Objectif : Additionner le nombre de ménage, d'emploi et de population pour les communes qui ont fusionnées (référence table fusion de commune "visufoncier.insee_fusioncom"). 
--exemple : La Chapelle Janson (35062) et Fleurigné (35112) on fusionné en La chapelle Fleurigné. 
--Si la population était de 400 à La chapelle Janson et 200 à Fleurigné (chiffres fictifs), le résultat du traitement sera La Chapelle Fleurigné - 35062 - 600

--------------------
--Population 
--------------------
ALTER TABLE visufoncier.insee_popmun
ADD COLUMN updated integer;

UPDATE visufoncier.insee_popmun AS vp
SET 
    updated = 1,
    codgeo = (SELECT vf.com_fin FROM visufoncier.insee_fusioncom AS vf WHERE vf.com_ini = vp.codgeo),
    libgeo = (SELECT vf.lib_com_fin FROM visufoncier.insee_fusioncom AS vf WHERE vf.com_ini = vp.codgeo)
WHERE EXISTS (
    SELECT 1 FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = vp.codgeo AND vf.com_ini <> vf.com_fin
);

INSERT INTO visufoncier.insee_popmun (codgeo, reg, dep, libgeo)
SELECT 
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_popmun
WHERE 
    updated = 1;

-- Étape 2: Mettre à jour les valeurs pmun dans une nouvelle ligne avec la somme des valeurs correspondant au même codgeo
UPDATE visufoncier.insee_popmun AS vp
SET 
	updated = 2, 
    pmun2021 = (
        SELECT COALESCE(SUM(vp_inner.pmun2021), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2020 = (
        SELECT COALESCE(SUM(vp_inner.pmun2020), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2019 = (
        SELECT COALESCE(SUM(vp_inner.pmun2019), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2018 = (
        SELECT COALESCE(SUM(vp_inner.pmun2018), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2017 = (
        SELECT COALESCE(SUM(vp_inner.pmun2017), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2016 = (
        SELECT COALESCE(SUM(vp_inner.pmun2016), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2015 = (
        SELECT COALESCE(SUM(vp_inner.pmun2015), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2014 = (
        SELECT COALESCE(SUM(vp_inner.pmun2014), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2013 = (
        SELECT COALESCE(SUM(vp_inner.pmun2013), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2012 = (
        SELECT COALESCE(SUM(vp_inner.pmun2012), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2011 = (
        SELECT COALESCE(SUM(vp_inner.pmun2011), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2010 = (
        SELECT COALESCE(SUM(vp_inner.pmun2010), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2009 = (
        SELECT COALESCE(SUM(vp_inner.pmun2009), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2008 = (
        SELECT COALESCE(SUM(vp_inner.pmun2008), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2007 = (
        SELECT COALESCE(SUM(vp_inner.pmun2007), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    ),
    pmun2006 = (
        SELECT COALESCE(SUM(vp_inner.pmun2006), 0)
        FROM visufoncier.insee_popmun AS vp_inner
        WHERE vp_inner.codgeo = vp.codgeo
    )
FROM 
    visufoncier.insee_popmun AS vp_source
WHERE 
    vp.codgeo = vp_source.codgeo
    AND vp_source.updated = 1
    AND vp.pmun2021 IS NULL; -- Vérifie que les champs pmun2021 sont vides dans la nouvelle ligne

-- Étape 3: Supprimer les lignes ayant le même "codgeo" que les lignes où updated<>0, sauf celles où updated=0
DELETE FROM visufoncier.insee_popmun AS vp
WHERE updated = 1;

----------------
--Ménage 2020
----------------

ALTER TABLE visufoncier.insee_menage_2020
ADD COLUMN updated INTEGER;

UPDATE visufoncier.insee_menage_2020 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
      AND (vf.com_ini <> vf.com_fin )  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);
UPDATE visufoncier.insee_menage_2020 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
	AND ( vf.com_ini = vf.com_fin)
      AND ( vf.lib_com_ini <> vf.lib_com_fin)  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);
-- Insérer distinctement dans la table "visufoncier.insee_menage_2020" les enregistrements mis à jour
INSERT INTO visufoncier.insee_menage_2020 (codgeo, reg, dep, libgeo)
SELECT DISTINCT ON (codgeo)
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_menage_2020
WHERE 
    updated = 1;

-- Mettre à jour la colonne "updated" et le champ "c20_men" dans la table "visufoncier.insee_menage_2020"
UPDATE visufoncier.insee_menage_2020 AS im
SET 
    updated = 2,
    c20_men = (
        SELECT COALESCE(SUM(im_source.c20_men), 0)
        FROM visufoncier.insee_menage_2020 AS im_source
        WHERE im.codgeo = im_source.codgeo
    )
    FROM visufoncier.insee_menage_2020 AS im_source
    WHERE im.c20_men IS NULL 
      AND im_source.updated = 1;

-- Supprimer les enregistrements obsolètes de la table "visufoncier.insee_menage_2020"
DELETE FROM visufoncier.insee_menage_2020 AS im
 WHERE updated =1;


--------------
--Ménage 2011
--------------


ALTER TABLE visufoncier.insee_menage_2011
ADD COLUMN updated INTEGER;

UPDATE visufoncier.insee_menage_2011 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
      AND (vf.com_ini <> vf.com_fin )  
);
UPDATE visufoncier.insee_menage_2011 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
	AND ( vf.com_ini = vf.com_fin)
      AND ( vf.lib_com_ini <> vf.lib_com_fin)  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);
-- Insérer distinctement dans la table "visufoncier.insee_menage_2011" les enregistrements mis à jour
INSERT INTO visufoncier.insee_menage_2011 (codgeo, reg, dep, libgeo)
SELECT DISTINCT ON (codgeo)
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_menage_2011
WHERE 
    updated = 1;

-- Mettre à jour la colonne "updated" et le champ "c11_men" dans la table "visufoncier.insee_menage_2011"
UPDATE visufoncier.insee_menage_2011 AS im
SET 
    updated = 2,
    c11_men = (
        SELECT COALESCE(SUM(im_source.c11_men), 0)
        FROM visufoncier.insee_menage_2011 AS im_source
        WHERE im.codgeo = im_source.codgeo
    )
    FROM visufoncier.insee_menage_2011 AS im_source
    WHERE im.c11_men IS NULL 
      AND im_source.updated = 1;

-- Supprimer les enregistrements obsolètes de la table "visufoncier.insee_menage_2011"
DELETE FROM visufoncier.insee_menage_2011 AS im
 WHERE updated =1;
--------------
--Ménage 2017
--------------

ALTER TABLE visufoncier.insee_menage_2017
ADD COLUMN updated INTEGER;

UPDATE visufoncier.insee_menage_2017 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
      AND (vf.com_ini <> vf.com_fin ) 
);
UPDATE visufoncier.insee_menage_2017 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
	AND ( vf.com_ini = vf.com_fin)
      AND ( vf.lib_com_ini <> vf.lib_com_fin)  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);
-- Insérer distinctement dans la table "visufoncier.insee_menage_2017" les enregistrements mis à jour
INSERT INTO visufoncier.insee_menage_2017 (codgeo, reg, dep, libgeo)
SELECT DISTINCT ON (codgeo)
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_menage_2017
WHERE 
    updated = 1;

-- Mettre à jour la colonne "updated" et le champ "c17_men" dans la table "visufoncier.insee_menage_2017"
UPDATE visufoncier.insee_menage_2017 AS im
SET 
    updated = 2,
    c17_men = (
        SELECT COALESCE(SUM(im_source.c17_men), 0)
        FROM visufoncier.insee_menage_2017 AS im_source
        WHERE im.codgeo = im_source.codgeo
    )
    FROM visufoncier.insee_menage_2017 AS im_source
    WHERE im.c17_men IS NULL 
      AND im_source.updated = 1;

-- Supprimer les enregistrements obsolètes de la table "visufoncier.insee_menage_2017"
DELETE FROM visufoncier.insee_menage_2017 AS im
 WHERE updated =1;

--------------
--Ménage 2018
--------------

ALTER TABLE visufoncier.insee_menage_2018
ADD COLUMN updated INTEGER;

UPDATE visufoncier.insee_menage_2018 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
      AND (vf.com_ini <> vf.com_fin )  
);
UPDATE visufoncier.insee_menage_2018 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
	AND ( vf.com_ini = vf.com_fin)
      AND ( vf.lib_com_ini <> vf.lib_com_fin)  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);
-- Insérer distinctement dans la table "visufoncier.insee_menage_2018" les enregistrements mis à jour
INSERT INTO visufoncier.insee_menage_2018 (codgeo, reg, dep, libgeo)
SELECT DISTINCT ON (codgeo)
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_menage_2018
WHERE 
    updated = 1;

-- Mettre à jour la colonne "updated" et le champ "c18_men" dans la table "visufoncier.insee_menage_2018"
UPDATE visufoncier.insee_menage_2018 AS im
SET 
    updated = 2,
    c18_men = (
        SELECT COALESCE(SUM(im_source.c18_men), 0)
        FROM visufoncier.insee_menage_2018 AS im_source
        WHERE im.codgeo = im_source.codgeo
    )
    FROM visufoncier.insee_menage_2018 AS im_source
    WHERE im.c18_men IS NULL 
      AND im_source.updated = 1;

-- Supprimer les enregistrements obsolètes de la table "visufoncier.insee_menage_2018"
DELETE FROM visufoncier.insee_menage_2018 AS im
 WHERE updated =1;

--------------
--Emploi 2020
--------------
ALTER TABLE visufoncier.insee_emploi_2020
ADD COLUMN updated INTEGER;

UPDATE visufoncier.insee_emploi_2020 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
      AND (vf.com_ini <> vf.com_fin )  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);

UPDATE visufoncier.insee_emploi_2020 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
	AND ( vf.com_ini = vf.com_fin)
      AND ( vf.lib_com_ini <> vf.lib_com_fin)  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);

-- Insérer distinctement dans la table "visufoncier.insee_emploi_2020" les enregistrements mis à jour
INSERT INTO visufoncier.insee_emploi_2020 (codgeo, reg, dep, libgeo)
SELECT DISTINCT ON (codgeo)
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_emploi_2020
WHERE 
    updated = 1;

-- Mettre à jour la colonne "updated" et le champ "p20_emplt" dans la table "visufoncier.insee_emploi_2020"
UPDATE visufoncier.insee_emploi_2020 AS im
SET 
    updated = 2,
    p20_emplt = (
        SELECT COALESCE(SUM(im_source.p20_emplt), 0)
        FROM visufoncier.insee_emploi_2020 AS im_source
        WHERE im.codgeo = im_source.codgeo
    )
    FROM visufoncier.insee_emploi_2020 AS im_source
    WHERE im.p20_emplt IS NULL 
      AND im_source.updated = 1;

-- Supprimer les enregistrements obsolètes de la table "visufoncier.insee_emploi_2020"
DELETE FROM visufoncier.insee_emploi_2020 AS im
WHERE updated = 1;


--------------
--Emploi 2011
--------------

ALTER TABLE visufoncier.insee_emploi_2011
ADD COLUMN updated REAL;

UPDATE visufoncier.insee_emploi_2011 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
      AND (vf.com_ini <> vf.com_fin ) 
);

UPDATE visufoncier.insee_emploi_2011 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
	AND ( vf.com_ini = vf.com_fin)
      AND ( vf.lib_com_ini <> vf.lib_com_fin)  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);



-- Insérer distinctement dans la table "visufoncier.insee_emploi_2011" les enregistrements mis à jour
INSERT INTO visufoncier.insee_emploi_2011 (codgeo, reg, dep, libgeo)
SELECT DISTINCT ON (codgeo)
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_emploi_2011
WHERE 
    updated = 1;

-- Mettre à jour la colonne "updated" et le champ "p11_emplt" dans la table "visufoncier.insee_emploi_2011"
UPDATE visufoncier.insee_emploi_2011 AS im
SET 
    updated = 2,
    p11_emplt = (
        SELECT COALESCE(SUM(im_source.p11_emplt), 0)
        FROM visufoncier.insee_emploi_2011 AS im_source
        WHERE im.codgeo = im_source.codgeo
    )
    FROM visufoncier.insee_emploi_2011 AS im_source
    WHERE im.p11_emplt IS NULL 
      AND im_source.updated = 1;

-- Supprimer les enregistrements obsolètes de la table "visufoncier.insee_emploi_2011"
DELETE FROM visufoncier.insee_emploi_2011 AS im
WHERE updated = 1;
  

  
--------------
--Emploi 2017
--------------

ALTER TABLE visufoncier.insee_emploi_2017
ADD COLUMN updated REAL;

UPDATE visufoncier.insee_emploi_2017 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
      AND (vf.com_ini <> vf.com_fin ) 
);

UPDATE visufoncier.insee_emploi_2017 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
	AND ( vf.com_ini = vf.com_fin)
      AND ( vf.lib_com_ini <> vf.lib_com_fin)  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);



-- Insérer distinctement dans la table "visufoncier.insee_emploi_2017" les enregistrements mis à jour
INSERT INTO visufoncier.insee_emploi_2017 (codgeo, reg, dep, libgeo)
SELECT DISTINCT ON (codgeo)
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_emploi_2017
WHERE 
    updated = 1;

-- Mettre à jour la colonne "updated" et le champ "p17_emplt" dans la table "visufoncier.insee_emploi_2017"
UPDATE visufoncier.insee_emploi_2017 AS im
SET 
    updated = 2,
    p17_emplt = (
        SELECT COALESCE(SUM(im_source.p17_emplt), 0)
        FROM visufoncier.insee_emploi_2017 AS im_source
        WHERE im.codgeo = im_source.codgeo
    )
    FROM visufoncier.insee_emploi_2017 AS im_source
    WHERE im.p17_emplt IS NULL 
      AND im_source.updated = 1;

-- Supprimer les enregistrements obsolètes de la table "visufoncier.insee_emploi_2017"
DELETE FROM visufoncier.insee_emploi_2017 AS im
WHERE updated = 1;
  
--------------
--Emploi 2018
--------------

ALTER TABLE visufoncier.insee_emploi_2018
ADD COLUMN updated REAL;

UPDATE visufoncier.insee_emploi_2018 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
      AND (vf.com_ini <> vf.com_fin ) 
);

UPDATE visufoncier.insee_emploi_2018 AS ve
SET 
    updated = 1,
    codgeo = (
        SELECT vf.com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.com_fin LIMIT 1
    ),
    libgeo = (
        SELECT vf.lib_com_fin 
        FROM visufoncier.insee_fusioncom AS vf 
        WHERE vf.com_ini = ve.codgeo 
        ORDER BY vf.lib_com_fin LIMIT 1
    )
WHERE EXISTS (
    SELECT 1 
    FROM visufoncier.insee_fusioncom AS vf 
    WHERE vf.com_ini = ve.codgeo 
	AND ( vf.com_ini = vf.com_fin)
      AND ( vf.lib_com_ini <> vf.lib_com_fin)  -- Condition pour inclure les cas où lib_com_ini et lib_com_fin sont différents
);



-- Insérer distinctement dans la table "visufoncier.insee_emploi_2018" les enregistrements mis à jour
INSERT INTO visufoncier.insee_emploi_2018 (codgeo, reg, dep, libgeo)
SELECT DISTINCT ON (codgeo)
    codgeo, 
    reg, 
    dep, 
    libgeo
FROM 
    visufoncier.insee_emploi_2018
WHERE 
    updated = 1;

-- Mettre à jour la colonne "updated" et le champ "p18_emplt" dans la table "visufoncier.insee_emploi_2018"
UPDATE visufoncier.insee_emploi_2018 AS im
SET 
    updated = 2,
    p18_emplt = (
        SELECT COALESCE(SUM(im_source.p18_emplt), 0)
        FROM visufoncier.insee_emploi_2018 AS im_source
        WHERE im.codgeo = im_source.codgeo
    )
    FROM visufoncier.insee_emploi_2018 AS im_source
    WHERE im.p18_emplt IS NULL 
      AND im_source.updated = 1;

-- Supprimer les enregistrements obsolètes de la table "visufoncier.insee_emploi_2018"
DELETE FROM visufoncier.insee_emploi_2018 AS im
WHERE updated = 1;
  